import std.stdio;
import std.conv;
import std.file;

void print(string str)
{
    writeln(str,"\x21");
}

void main(string[] args)
{
    //print("hello");
    auto b=2;
    if(args.length==1)
    {
        print((b.to!string));
    }
    File bs=File(args[1],"rb+");
    if(idxstring(bs,"DVRS"))
    {
        bs.seek(0x8);
        auto start_offset=readint32(bs);
        bs.seek(start_offset);
        if(idxstring(bs,"TXPC"))
        {
            bs.seek(0x8+start_offset);
            auto txpc_cu_offset=readint32(bs);
            start_offset+=txpc_cu_offset;
            bs.seek(start_offset);
            auto curr_offset=bs.tell;
            if(idxstring(bs,"TXP\x03"))
            {
                auto count=readint32(bs);
                print(count.to!string);
                bs.seek(curr_offset+12);
                auto start_txp=readint32(bs);

                curr_offset+=start_txp;
                bs.seek(curr_offset);
                for(int a=0;a<count;a=a+1)
                {
                    if(idxstring(bs,"TXP\x04"))
                    {
                        auto txp02_count=readint32(bs);
                        bs.seek(bs.tell+4);
                        auto boff=readint32(bs);
                        curr_offset+=boff;
                        
                        
                        bs.seek(curr_offset);
                        for(int i=0;i<txp02_count;i=i+1)
                        {
                            ulong txp02_size=0;
                            auto txp02_start_offest=bs.tell;
                            if(idxstring(bs,"TXP\x02"))
                            {
                                auto width=readint32(bs);
                                auto height=readint32(bs);
                                auto tex_type=readint32(bs);
                                bs.seek(bs.tell+4);
                                auto block_size=readint32(bs);
                                
                                ulong bstart=bs.tell;
                                bs.seek(bs.tell+block_size);
                                auto bend=bs.tell;
                                string dds_type="UNKNOW";
                                if(tex_type==9)
                                {
                                    dds_type="DXT5";
                                }

                                if(tex_type==7)
                                {
                                    dds_type="DXT1";
                                }
                                print((a.to!string)~(i.to!string)~":width:"~
                                    (width.to!string)~":height:"~
                                    (height.to!string)~":type:"~
                                    (tex_type.to!string)~":start:"~
                                    (bstart.to!string)~":size:"~
                                    (block_size.to!string)~"::"~dds_type
                                );
                                split_txp_data(bs,(a.to!string)~
                                (i.to!string)~
                                "_"~(width.to!string)~
                                "_"~(height.to!string)~
                                ".dds",bstart,block_size,width,height,tex_type);
                                txp02_size=txp02_start_offest+0x4c;
                                txp02_size=txp02_size+block_size;
                            }
                            print("TXPSTART:"~txp02_start_offest.to!string~":END:"~txp02_size.to!string);
                        }
                        print(bs.tell.to!string);
                        curr_offset=bs.tell;
                    }
                    else
                    {
                        break;
                    }
                }
            }
        }
    }
    bs.close;
}
bool idxstring(File bs,string a)
{
    auto string_size=a.length;
    auto yz_str=bs.rawRead(new char[string_size]).dup;
    return yz_str == a;
}
int readint32(File bs)
{
	int result=bs.rawRead(new int[1])[0];
	//pos=bs.tell;
	return result;
}
void split_txp_data(File bs,string fname,ulong fstart,int fsize,int width,int height,int tex_type)
{
    auto tmp_off=bs.tell;
    bs.seek(fstart);

    //auto wbuff=bs.rawRead(new byte[fsize]);
    File ws=File(fname,"w");
    ws.rawWrite("\x44\x44\x53\x20\x7C\x00\x00\x00\x07\x10\x0A\x00");
    int[] a=[height,width];
    ws.rawWrite(a);
    //ws.rawWrite(width);
    ws.rawWrite("\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x20\x00\x00\x00\x05\x00\x00\x00\x44\x58\x54");
    if(tex_type==9)
    {
        ws.rawWrite("5");
    }else{
        ws.rawWrite("1");
    }
    ws.rawWrite("\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x08\x10\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00");
    
    ws.rawWrite(bs.rawRead(new byte[fsize]));
    bs.seek(tmp_off);
    ws.close();
}
