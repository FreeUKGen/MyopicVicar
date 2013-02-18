# MyopicVicar

MyopicVicar is an administrative application for preparing and loading images
into a transcription tool based on Zooniverse Scribe.


## Getting Started

### Linux

1. Link the assets directory to public/ under your Scribe install
       <tt>ln -s ./public/assets/images/working ../Scribe/public/images</tt> 
       (Assumes that Scribe and MyopicVicar are sibling directories)

### Windows

1. use mklink
2. rename the folder C:\....\GitHub\Scribe\public\images so that Windows may make the folder.
3. mklink /J C:\....\GitHub\Scribe\public\images C:\......\GitHub\MyopicVicar\public\assets\images\working

## Installation Instructions

Please see [Installation Instructions](https://github.com/FreeUKGen/MyopicVicar/wiki/Installation-Instructions) for more information.
