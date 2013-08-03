#
# File to create a very simple waveform.
#

time_step = 0.001

amplitude = [0.2, 0.8, 0.6]
frequency = [10, 14, 18]

f = File.open('sample.sql', 'w')
f.write %{
BEGIN TRANSACTION;
CREATE TABLE _senders (name TEXT PRIMARY KEY, id INTEGER UNIQUE);
INSERT INTO "_senders" VALUES('ch1',1);
CREATE TABLE _experiment_metadata (key TEXT PRIMARY KEY, value TEXT);
INSERT INTO "_experiment_metadata" VALUES('start_time','#{Time.now.to_i}');
CREATE TABLE "wave" (oml_sender_id INTEGER, oml_seq INTEGER, oml_ts_client REAL, oml_ts_server REAL, "t" REAL, "y" REAL);
}

1000.times do |i|
  time = i * time_step
  y = 0
  3.times do |j|
    y += amplitude[j] * Math.sin(2 * Math::PI * frequency[j] * time)
  end
  f.write "INSERT INTO \"wave\" VALUES(1,#{i},#{time},#{time},#{time},#{y});\n"
end
f.write "END TRANSACTION;\n"
f.close