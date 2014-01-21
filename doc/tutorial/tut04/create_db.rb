require 'sequel'

File.unlink('gen.sq3') if File.readable?('gen.sq3')
db = Sequel.connect 'sqlite://gen.sq3'

db.create_table '_senders'.to_sym do
  Integer :id
  String :name
end
db['_senders'.to_sym].insert(id: 1, name: 'test')

db.create_table :voltage do
  Integer :oml_sender_id
  Integer :oml_seq
  Float :oml_ts_client
  Float :oml_ts_server
  String :generator
  Float :voltage
  Float :noise
end
$out_t = db[:voltage]
$seq = 0


$start = Time.now.to_i
def measure(gen, voltage, noise)
  now = Time.now.to_f - $start
  r = {
    oml_sender_id: 1, oml_seq: $seq,
    oml_ts_client: now, oml_ts_server: now,
    generator: gen,
    voltage: voltage,
    noise: noise
  }
  $out_t.insert(r)
  $seq += 1
end

def r; rand - 0.5; end
def noise(mul); return 4 * mul * r() * r(); end

ang = 0;
step = Math::PI * 15 / 180;
loop do
  n1 = noise(0.02);
  a1 = Math.sin(ang);
  measure('gen1', a1 + n1, n1);
  n2 = noise(0.01);
  a2 = Math.cos(ang);
  measure('gen2', a2 + n2, n2);
  ang += step;

  sleep 0.2
end


