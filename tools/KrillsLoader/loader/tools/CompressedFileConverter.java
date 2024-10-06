import java.io.*;

public class CompressedFileConverter
{
    public static void main(String[] params)
    {
        if (params.length < 4 || params.length > 5 || (!params[0].equals("bb")
		                                            && !params[0].equals("dnx")
		                                            && !params[0].equals("exo")
													&& !params[0].equals("lc")))
        {
            System.out.println("Usage:\njava CompressedFileConverter bb|dnx|exo|lc [safety-margin] uncompressed_infile compressed_infile outfile.");
        }
        else
        {
            if (params.length == 4)
            {
                new CompressedFileConverter(params[0], params[0].equals("dnx") ? 1 : 3 /* default safety-margin */, params[1], params[2], params[3]);
            }
            else
            {
                new CompressedFileConverter(params[0], Integer.parseInt(params[1]), params[2], params[3], params[4]);
            }
        }
    }

    CompressedFileConverter(String compressor, int safety_margin, String uncompressedInFileName, String compressedInFileName, String outFileName)
    {
        readUncompressedInFile(compressor, uncompressedInFileName);
        readCompressedInFile(compressor, compressedInFileName);
        convertCompressedInFile(compressor, safety_margin);
        writeOutFile(outFileName);
    }    

    void readUncompressedInFile(String compressor, String uncompressedInFileName)
    {
        FileInputStream uncompressedInFile = null;
        try
        {
            uncompressedInFile = new FileInputStream(uncompressedInFileName);
        }
        catch (IOException e)
        {
            System.out.println(uncompressedInFileName + " couldn't be opened.");
            System.exit(-1);
        }

        try
        {
            _uncompressedInFileLength = 0;

            _uncompressedInFileLoadAddress = uncompressedInFile.read() | (uncompressedInFile.read() << 8);

            int value;
            int i = 2;
            while ((value = uncompressedInFile.read()) != -1)
            {
                i++;
            }
            uncompressedInFile.close();
            _uncompressedInFileLength = i;
        }
        catch (IOException e)
        {
            System.out.println( "IO error while reading " + uncompressedInFileName + "." );
            System.exit(-1);
        }
    }

    void readCompressedInFile(String compressor, String compressedInFileName)
    {
        FileInputStream compressedInFile = null;
        try
        {
            compressedInFile = new FileInputStream(compressedInFileName);
        }
        catch (IOException e)
        {
            System.out.println(compressedInFileName + " couldn't be opened.");
            System.exit(-1);
        }

        try
        {
            _compressedFileData = new byte[65536];
            _compressedInFileLength = 0;
            
            int i = 2;

            if (compressor.equals("bb"))
            {
                // remove start address
                compressedInFile.read();
                compressedInFile.read();
            } else if (compressor.equals("dnx")) {
                // add destination address
                _compressedFileData[i++] = (byte) (_uncompressedInFileLoadAddress & 0xff);
                _compressedFileData[i++] = (byte) (_uncompressedInFileLoadAddress >> 8);
            }

            int value;
            while ((value = compressedInFile.read()) != -1)
            {
                _compressedFileData[i++] = (byte) value;
            }
            compressedInFile.close();
            _compressedInFileLength = i;
        }
        catch (IOException e)
        {
            System.out.println( "IO error while reading " + compressedInFileName + "." );
            System.exit(-1);
        }
    }

    void convertCompressedInFile(String compressor, int safety_margin)
    {
        int compressedLoadAddress = _uncompressedInFileLoadAddress + _uncompressedInFileLength + safety_margin - _compressedInFileLength;
        
        _compressedFileData[0] = (byte) compressedLoadAddress;
        _compressedFileData[1] = (byte) (compressedLoadAddress >> 8);
    }

    void writeOutFile(String outFileName)
    {
        FileOutputStream outFile = null;
        try
        {
            outFile = new FileOutputStream(outFileName);
        }
        catch (IOException e)
        {
            System.out.println(outFile + " couldn't be opened.");
            System.exit(-1);
        }
        
        try
        {
            for (int i = 0; i < _compressedInFileLength; i++)
            {
                outFile.write(_compressedFileData[i]);
            }
            
            outFile.close();
        }
        catch (IOException e)
        {
            System.out.println("IO error while writing " + outFileName + ".");
            System.exit(-1);
        }        
    }
    
    private byte[] _compressedFileData = null;
    private int _uncompressedInFileLoadAddress;
    private int _compressedInFileLength;
    private int _uncompressedInFileLength;
}
