# frozen_string_literal: true
require 'bundler'

Bundler.setup

require 'benchmark/ips'
require 'terminal-table'

require 'json'
require 'msgpack'
require 'oj'

SAMPLE = {
  array: %w(a b c').freeze,
  boolean: true,
  fixnum: 123,
  float: 123.456,
  hash: { 'key' => 'value' }.freeze,
  null: nil,
  string: 'string',
  symbol: :symbol
}.freeze

serializers = []
serializers << {
  name: 'Marshal',
  serialize: ->(v) { Marshal.dump(v) },
  deserialize: ->(v) { Marshal.load(v) }
}
serializers << {
  name: 'Oj',
  serialize: ->(v) { Oj.dump(v) },
  deserialize: ->(v) { Oj.load(v) }
}
serializers << {
  name: 'JSON',
  serialize: ->(v) { JSON.generate(v) },
  deserialize: ->(v) { JSON.parse(v) }
}
serializers << {
  name: 'MessagePack',
  serialize: ->(v) { MessagePack.pack(v) },
  deserialize: ->(v) { MessagePack.unpack(v) }
}

puts '### Serializer Samples #########################'
value = { 'k1' => 'v', 'k2' => [1, 2] }
results = []
results << ['Original', '', '', '', value.to_s, '']
serializers.each do |name:, serialize:, deserialize:|
  serialized_value = serialize.call(value)
  deserialized_value = deserialize.call(serialized_value)
  unsupport_types = []
  SAMPLE.each do |k, v|
    unsupport_types << k unless v == deserialize.call(serialize.call(v))
  end
  results << [
    name,
    serialized_value.gsub(/[^[:print:]]/, '?'),
    serialized_value.dump,
    serialized_value.bytesize,
    deserialized_value.to_s,
    unsupport_types.join(', ')
  ]
end
result_table = Terminal::Table.new(
  headings: [
    'Name',
    'Serialized',
    'Serialized(dump)',
    'Serialized(bytes)',
    'Deserialized',
    'Unsupport types'
  ],
  rows: results
)
result_table.align_column(3, :right)
puts result_table
puts ''

puts '### Serialize Benchmark #########################'
Benchmark.ips do |x|
  serializers.each do |name:, serialize:, deserialize:|
    x.report(name) { serialize.call(SAMPLE) }
  end
  x.compare!
end

puts '### Deserialize Benchmark #######################'
Benchmark.ips do |x|
  serializers.each do |name:, serialize:, deserialize:|
    serialized_value = serialize.call(SAMPLE)
    x.report(name) { deserialize.call(serialized_value) }
  end
  x.compare!
end
