# MyopicVicar

MyopicVicar is an administrative application for preparing and loading images
into a transcription tool based on Zooniverse Scribe.


## Getting Started

### Linux/*nix

1. Link the assets directory to public/ under your Scribe install
       <tt>ln -s ./public/assets/images/working ../Scribe/public/images</tt> 
       (Assumes that Scribe and MyopicVicar are sibling directories)

### Windows

1. in windows use mklink
2. rename the folder C:\....\GitHub\Scribe\public\images so that windows may make the folder
3. mklink /J C:\....\GitHub\Scribe\public\images C:\......\GitHub\MyopicVicar\public\assets\images\working

