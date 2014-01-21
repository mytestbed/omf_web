require 'oml4r'


class GenMP < OML4R::MPBase
  name :voltage

  param :generator
  param :voltage, :type => :double
  param :noise, :type => :double
end

opts = {
  :appName => 'gen',
  :domain => 'foo',
  :collect => 'tcp:localhost:4003'
}
OML4R::init(ARGV, opts)

def r; rand - 0.5; end
def noise(mul); return 4 * mul * r() * r(); end

ang = 0;
step = Math::PI * 15 / 180;
loop do
  n1 = noise(0.02);
  a1 = Math.sin(ang);
  GenMP.inject('gen1', a1 + n1, n1);
  n2 = noise(0.01);
  a2 = Math.cos(ang);
  GenMP.inject('gen2', a2 + n2, n2);
  ang += step;

  sleep 0.2
end


