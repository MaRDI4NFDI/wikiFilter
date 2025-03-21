#!/usr/bin/python3
import os
import bz2
import argparse

def split_xml(filename, splitsize, dir, tags, template, keywords):
    ''' The function gets the filename of wiktionary.xml.bz2 file as input and creates
    smaller chunks of it in the directory chunks.
    '''
    # Check and create chunk directory
    if not os.path.exists(dir):
        os.mkdir(dir)

    # Counters
    pagecount = 0
    filecount = 1
    ismatch = 2
    header = ""
    footer = "</mediawiki>"
    tempstr = ""
    # Open chunkfile in write mode
    chunkname = lambda filecount: os.path.join(dir, "chunk-" + str(filecount) + ".xml.bz2")
    chunkfile = bz2.BZ2File(chunkname(filecount), 'w')
    
    # Read line by line
    bzfile = bz2.BZ2File(filename)
    tags = tags.split(',')
    if keywords:
        keywords = keywords.split(',')
    else:
        keywords = []

    # The header
    for line in bzfile:
        header += line.decode('utf-8')  # decode the bytes to string
        if '</siteinfo>' in header:
            break
    print(header)
    chunkfile.write(header.encode('utf-8'))  # write as bytes

    # And the rest
    for line in bzfile:
        line = line.decode('utf-8')  # decode the bytes to string
        # The </page> determines new wiki page
        if '<page' in line:
            tempstr = ""
            ismatch = 0
        tempstr = tempstr + line
        
        for tag in tags:
            if '&lt;/' + tag + '&gt;' in line:
                ismatch = 1
                pagecount += 1
                print(splitsize * filecount + pagecount)
        for keyword in keywords:
            if keyword in line:
                ismatch = 1
                pagecount += 1
                print(splitsize * filecount + pagecount)
        if template and ('<ns>10</ns>' in line or '<ns>828</ns>' in line):
            ismatch = 1
            pagecount += 1
            print('template')
        if '</page>' in line:
            if ismatch == 1:
                chunkfile.write(tempstr.encode('utf-8'))  # write as bytes
                tempstr = ""
        if pagecount > splitsize:
            # print chunkname() # For Debugging
            chunkfile.write(footer.encode('utf-8'))  # write as bytes
            chunkfile.close()
            pagecount = 0  # RESET pagecount
            filecount += 1  # increment filename
            chunkfile = bz2.BZ2File(chunkname(filecount), 'w')
            chunkfile.write(header.encode('utf-8'))  # write as bytes

    try:
        chunkfile.write(footer.encode('utf-8'))  # write as bytes
        chunkfile.close()
    except Exception as e:
        print('Error:', e)


if __name__ == '__main__':  # When the script is self-run
    parser = argparse.ArgumentParser(description='Extract wikipages that contain the math tag',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('-f', '--filename', help='The bz2-file to be split and filtered',
        default='enwiki-latest-pages-articles.xml.bz2', dest='file')
    parser.add_argument('-s', '--splitsize', help='The number of pages contained in each split',
        default=1000000, type=int, dest='size')
    parser.add_argument('-d', '--outputdir', help='The directory name where the files go',
        default='wout', type=str, dest='dir')
    parser.add_argument('-t', '--tagname', help='Comma separated list of the tag names to search for',
        default='math,ce,chem', type=str, dest='tags')
    parser.add_argument('-k', '--keyword', help='Comma separated list of the keywords to search for',
        default='', type=str, dest='keywords')
    parser.add_argument("-v", "--verbosity", action="count", default=0)
    parser.add_argument('-T', '--template', help='Include all templates',
        action="store_true", dest='template')
    args = parser.parse_args()
    split_xml(args.file, args.size, args.dir, args.tags, args.template, args.keywords)
