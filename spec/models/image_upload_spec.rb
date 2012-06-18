

require 'spec_helper'

describe ImageUpload do
  SIMPLE_DIR = '/home/benwbrum/dev/freeukgen/mvuploads/simpletest'
  ZIP_DIR = '/home/benwbrum/dev/freeukgen/mvuploads/ziptest'
  MULTI_DIR = '/home/benwbrum/dev/freeukgen/mvuploads/multileveltest'
  HETERO_DIR = '/home/benwbrum/dev/freeukgen/mvuploads/heterogenoustest'
  PDF_DIR = '/home/benwbrum/dev/freeukgen/mvuploads/pdftest'


#  pending "basic stuff"
  
  it "can be instantiated" do
    ImageUpload.new.should be_an_instance_of(ImageUpload)
  end
  
  it "should be persisted" do
    ImageUpload.create(:upload_path => '/tmp').should be_persisted
  end
  
  it "should persist an upload directory" do
    iu = ImageUpload.new
    iu.upload_path = "/tmp"
    iu.save!
    id = iu.id
    iu2 = ImageUpload.find(id)
    iu2.upload_path.should eq("/tmp")
  end
  
  
  it "should check for valid upload directory" do
    iu = ImageUpload.new
    iu.upload_path = "foo"
    iu.should be_invalid
    iu.upload_path = '/tmp'
    iu.should be_valid
    
    TMPDIR = "/tmp/MyopicVicarTest"

    iu.upload_path = TMPDIR
    system("mkdir -p #{TMPDIR}")
    system("chmod ugo+rx #{TMPDIR}")
    iu.should be_valid

    system("chmod ugo-rx #{TMPDIR}")
    iu.should be_invalid
    system("chmod ugo+x #{TMPDIR}")
    iu.should be_invalid
    system("chmod ugo-x #{TMPDIR}")
    system("chmod ugo+r #{TMPDIR}")
    iu.should be_invalid
    system("chmod ugo+rx #{TMPDIR}")
    iu.should be_valid
    system("rmdir #{TMPDIR}")
    iu.should be_invalid
  end
 

  it "should copy to a working dir" do
    # create the dest dir
    iu=ImageUpload.new
    iu.upload_path=SIMPLE_DIR
    iu.initialize_working_dir
    wd = iu.originals_dir
    File.directory?(wd).should eq(true)


    # copy files over
    iu.copy_to_originals_dir
    old_ls = Dir.entries(iu.upload_path).sort
    new_ls = Dir.entries(wd).sort
    
    old_ls.should eq(new_ls)

    # 
  end
  
  it "should process files" do
    iu=ImageUpload.new
    iu.upload_path=SIMPLE_DIR
    iu.copy_to_originals_dir
    wd = iu.originals_dir
    iu.process_originals_dir(wd)

    iu.image_dir.count.should eq(1)
    iu.image_dir.first.image_file.count.should eq(Dir.glob(File.join(SIMPLE_DIR,"*")).count)
    
  end
  

  it "should unzip files" do 
    iu=ImageUpload.new
    iu.upload_path=ZIP_DIR
    iu.copy_to_originals_dir
    wd = iu.originals_dir
    iu.process_originals_dir(wd)

    # fs tests
    wd_ls = Dir.glob(File.join(wd,"*"))
    zd_ls = Dir.glob(File.join(wd,"Flintshire 1861","*"))
    wd_ls.count.should eq 2 # new dir and orig zipfile
    zd_ls.count.should eq 11
                     

    # db tests
    iu.image_dir.count.should eq(2)
    iu.image_dir.where(:path => /Flintshire.*/).first.image_file.count.should eq(11)
  end

  it "should unpack PDFs" do 
    iu=ImageUpload.new
    iu.upload_path=PDF_DIR
    iu.copy_to_originals_dir
    wd = iu.originals_dir
    iu.process_originals_dir(wd)

    # fs tests
    wd_ls = Dir.glob(File.join(wd,"*"))
    zd_ls = Dir.glob(File.join(wd,"SSCens Tutor_Hse_3p","*"))
    wd_ls.count.should eq 2 # new dir and orig zipfile
    zd_ls.count.should eq 5
                     

    # db tests
    iu.image_dir.count.should eq(2)
    iu.image_dir.where(:path => /SSCens.*/).first.image_file.count.should eq(5)
  end

  it "should deal with multiple levels" do 
    iu=ImageUpload.new
    iu.upload_path=MULTI_DIR
    iu.process_upload
    wd = iu.originals_dir

    # fs tests
    # top directory should equal original 4
    wd_ls = Dir.glob(File.join(wd,"*"))
    wd_ls.count.should eq(4)
    # dbdir should contain 0 dbfiles
    iu.image_dir.first.image_file.count.should eq(0)


    # zip directory should equal 2 (zipfile + extracted directory)
    zd = File.join(wd, "ziptest")
    zd_ls = Dir.glob(File.join(zd,"*"))
    zd_ls.count.should eq(2)
    # zip dbdir should contain 0 dbfiles
    iu.image_dir.where(:path => /ziptest$/).first.image_file.count.should eq(0)
    # zip subdir should equal 11
    zsd = File.join(zd, "Flintshire 1861")
    zsd_ls = Dir.glob(File.join(zsd,"*"))
    zsd_ls.count.should eq(11)
    # zip dbdir should contain 11 dbfiles
    iu.image_dir.where(:path => /ziptest\/Flintshire 1861$/).first.image_file.count.should eq(11)

    # pdf directory should equal 2 (pdfdir + extracted dir)
    pd = File.join(wd, "pdftest")
    pd_ls = Dir.glob(File.join(pd,"*"))
    pd_ls.count.should eq(2)
    # pdf dbdir should contain 0 dbfiles
    iu.image_dir.where(:path => /pdftest$/).first.image_file.count.should eq(0)
    # pdf subdir should equal 5
    psd = File.join(wd, "pdftest")
    psd_ls = Dir.glob(File.join(psd,"*"))
    psd_ls.count.should eq(2)
    # pdf sub dbdir should contain 5 dbfiles
    iu.image_dir.where(:path => /pdftest\/SSCens.*/).first.image_file.count.should eq(5)
    # 


    # hetero dir should equal 19 files + 5 extract dirs
    hd = File.join(wd, "heterogenoustest")
    hd_ls = Dir.glob(File.join(hd,"*"))
    hd_ls.count.should eq(24)
    # hetero dbdir should equal 19 files - 5 zipfiles - 1 non-image file
    iu.image_dir.where(:path => /heterogenoustest$/).first.image_file.count.should eq(13)
    # hetero pdf subdir should equal X files
    # pdf directory should equal 2 (pdfdir + extracted dir)
    hpd = File.join(hd, "SSCens Tutorial_Spread_1p")
    hpd_ls = Dir.glob(File.join(hpd,"*"))
    hpd_ls.count.should eq(2)
    # pdf dbdir should contain 1 dbfiles
#    iu.image_dir.each { |d| p d.path }
    iu.image_dir.where(:path => /heterogenoustest\/SSCens Tutorial_Spread_1p$/).first.image_file.count.should eq(2)

  end


  it "should only process image files" do
    iu=ImageUpload.new
    iu.upload_path=HETERO_DIR
    iu.copy_to_originals_dir
    wd = iu.originals_dir
    iu.process_originals_dir(wd)

    iu.image_dir.count.should eq(3+Dir.glob(File.join(HETERO_DIR,"*.zip")).count)
    iu.image_dir.first.image_file.count.should eq(Dir.glob(File.join(HETERO_DIR,"*.jpg")).count)
    
  end
  


end
