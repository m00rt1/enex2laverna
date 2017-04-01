Introduction
============

Workflow to migrate notes from Evernote export file to Laverna

Based on script initially implemented for Simplenote and script for building Laverna import file from Markdown files

- Evernote [link](http://www.evernote.com)
- Laverna [link](https://laverna.cc)
- Markdown [link](http://daringfireball.net/projects/markdown/)
- Docker [link](https://www.docker.com/)
- Docker Compose [link](https://docs.docker.com/compose/install/)

Installation
------------

- Install Docker
- Install Docker Compose

Usage
-----

- Create Evernote export file in `./input/notes.enex`

- Build service Docker images with
    
		$ ./build.sh
    
- Create MD notes from enex
    
		$ ./run-ever2simple.sh
    
- Create Laverna export zip from freshly installed app in `./laverna-backup.zip`
    
- Create Laverna import zip from MD files from previous step
    
		$ ./run-md2laverna.sh

- Import Laverna import zip to freshly installed app from `./to-import/laverna-backup.zip`

Notes and Caveats
-----------------

- Paths in usage are relative to repository root path

Resources
-----

ever2simple [link](http://github.com/claytron/ever2simple)
@magowiz "md batch import with bash script" [link](https://github.com/Laverna/laverna/issues/508#issuecomment-239631953)

TODO
----

- Rewrite everything

