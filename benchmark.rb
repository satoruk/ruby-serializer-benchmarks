# frozen_string_literal: true
require 'bundler'

Bundler.setup

require 'benchmark/ips'

require 'json'
require 'msgpack'
require 'oj'

SAMPLE = {
  array: ['a', 'b', 'c'].freeze,
  fixnum: 123,
  float: 123.456,
  hash: { key: 'value' }.freeze,
  string: 'string'.freeze,
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
