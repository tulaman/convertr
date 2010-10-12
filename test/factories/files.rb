Factory.define :file, :class => Convertr::File do |f|
  f.filename 'test.avi'
  f.location 'ftp://ftp.example.com/test.avi'
  f.convertor 'convertorX'
end
