Factory.define :task, :class => Convertr::Task do |t|
  t.association :file, :factory => :file
  t.bitrate 600
  t.crop true
  t.deinterlace true
end
