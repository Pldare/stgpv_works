require 'stringio'
require 'fileutils'
def load_dv_blc(a)
    magic=a.read(4)
    bsize=a.read(4).unpack("V")[0]
    boffs=a.read(4).unpack("V")[0]
    a.seek(boffs)
    return StringIO.new(a.read(bsize))
end
def load_dv_efc(a,count)
    bc=[]
    for i in 0...count
        now_off=a.pos
        magic=a.read(4)
        bsize=a.read(4).unpack("V")[0]
        boffs=a.read(4).unpack("V")[0]
        a.seek(now_off+boffs)
        bc<<StringIO.new(a.read(bsize))
    end
    return bc
end
def par_dv_efc(a)
    bc=[]
    a.seek(0x90)
    loop do
        now_off=a.pos
        magic=a.read(4).to_s
        break if magic == "EOFC"
        bsize=a.read(4).unpack("V")[0]
        boffs=a.read(4).unpack("V")[0]
        a.read(8)
        asize=a.read(4).unpack("V")[0]
        a.seek(now_off+boffs+asize)
        bc<<[magic,StringIO.new(a.read(bsize-asize))]
    end
    return bc
end
def par_dv_emit(a)
    bc=[]
    #a.seek(0x90)
    loop do
        now_off=a.pos
        magic=a.read(4).to_s
        break if magic == "EOFC"
        bsize=a.read(4).unpack("V")[0]
        boffs=a.read(4).unpack("V")[0]
        #a.read(8)
        #asize=a.read(4).unpack("V")[0]
        a.seek(now_off+boffs)#+asize)
        bc<<[magic,StringIO.new(a.read(bsize))]#-asize))]
    end
    return bc
end
def par_dv_curv(a)
    bc=[]
    #a.seek(0x20)
    bc<<["HEAD",StringIO.new(a.read(0x20))]
    loop do
        now_off=a.pos
        magic=a.read(4).to_s
        break if magic == "EOFC"
        bsize=a.read(4).unpack("V")[0]
        boffs=a.read(4).unpack("V")[0]
        a.read(8)
        asize=a.read(4).unpack("V")[0]
        a.seek(now_off+boffs)#+asize)
        bc<<[magic,StringIO.new(a.read(asize))]#-asize))]
    end
    return bc
end
def par_dv_curv_txt(a)
    fram_info=[]
    loop do
        break if a.pos == a.size
        a.read(2)
        key=a.read(2).unpack("v")[0]
        vau=a.read(4).unpack("F")[0]
        fram_info<<[key,vau]
    end
    return fram_info
end
#load lst
bfile_name=File.basename(ARGV[0],File.extname(ARGV[0]))
#LIST
lis_list=load_dv_blc(File.open(bfile_name+".lst"))
#GEFF
lis_geff=load_dv_blc(lis_list)
geff_count=lis_geff.read(4).unpack("V")[0]
geff_list=[]
for i in 0...geff_count
    geff_list<<lis_geff.read(0x80).to_s.gsub("\x00","")
end
print geff_list

#load dve
dve_dvef=load_dv_blc(File.open(bfile_name+".dve"))
#EFCTSssssss
dve_efcts=load_dv_efc(dve_dvef,geff_count)

FileUtils.mkdir_p("EFCT") unless File.exists?("EFCT")
elis=File.open("EFCT/list.txt","wb")
geff_count.times.map { |i|
    #puts i.size
    dve_efct=dve_efcts[i]
    sname=geff_list[i]
    dve_efct.seek(0)
    dve_efct_save_name="EFCT/#{sname}"
    File.open(dve_efct_save_name+".data","wb")<<dve_efct.read(dve_efct.size)
    dve_efct.seek(0)

    elis.puts sname
    FileUtils.mkdir_p(dve_efct_save_name) unless File.exists?(dve_efct_save_name)
    #efct
    dve_efct_chis=par_dv_efc(dve_efct)
    for j in 0...dve_efct_chis.size
        type=dve_efct_chis[j][0]
        dve_efct_chi=dve_efct_chis[j][1]

        dve_efct_chi.seek(0)
        dve_efct_chi_save_name="#{dve_efct_save_name}/#{sname}_#{j}_#{type}"
        File.open(dve_efct_chi_save_name,"wb")<<dve_efct_chi.read(dve_efct_chi.size)
        dve_efct_chi.seek(0)

        dve_efct_chi_emit_chis=par_dv_emit(dve_efct_chi)
        for k in 0...dve_efct_chi_emit_chis.size
            type1=dve_efct_chi_emit_chis[k][0]
            dve_efct_chi_emit_chi=dve_efct_chi_emit_chis[k][1]

            dve_efct_chi_emit_chi.seek(0)
            dve_efct_chi_emit_chi_save_name="#{dve_efct_save_name}/#{sname}_#{j}_#{type}_#{k}_#{type1}"
            File.open(dve_efct_chi_emit_chi_save_name,"wb")<<dve_efct_chi_emit_chi.read(dve_efct_chi_emit_chi.size)
            dve_efct_chi_emit_chi.seek(0)

            if type1 == "ANIM"
                dve_efct_chi_emit_chi_curvs=par_dv_emit(dve_efct_chi_emit_chi)
                for l in 0...dve_efct_chi_emit_chi_curvs.size
                    type2=dve_efct_chi_emit_chi_curvs[l][0]
                    dve_efct_chi_emit_chi_curv=dve_efct_chi_emit_chi_curvs[l][1]

                    dve_efct_chi_emit_chi_curv.seek(0)
                    dve_efct_chi_emit_chi_curv_save_name="#{dve_efct_save_name}/#{sname}_#{j}_#{type}_#{k}_#{type1}_#{l}_#{type2}"
                    File.open(dve_efct_chi_emit_chi_curv_save_name,"wb")<<dve_efct_chi_emit_chi_curv.read(dve_efct_chi_emit_chi_curv.size)
                    dve_efct_chi_emit_chi_curv.seek(0)
                    if type2 == "CURV"
                        curvs=par_dv_curv(dve_efct_chi_emit_chi_curv)

                        for o in 0...curvs.size
                            typ3=curvs[o][0]
                            curb=curvs[o][1]
                            curb_save_name=dve_efct_chi_emit_chi_curv_save_name+"_#{o}_#{typ3}"
                            curb.seek(0)
                            File.open(curb_save_name,"wb")<<curb.read(curb.size)
                            curb.seek(0)

                            #save txt
                            if typ3 == "KEYS"
                                curb_txt=par_dv_curv_txt(curb)
                                File.open(curb_save_name+".txt","wb") do |ws|
                                    for p in 0...curb_txt.size
                                        curb_chi=curb_txt[p]
                                        ws<<curb_chi.join(",")+"\n"
                                    end
                                end
                            end
                        end
                    end
                end
            elsif type1 == "EMIT"
            elsif type1 == "CURV"
                curvs=par_dv_curv(dve_efct_chi_emit_chi)

                for o in 0...curvs.size
                    typ3=curvs[o][0]
                    curb=curvs[o][1]
                    curb_save_name=dve_efct_chi_emit_chi_save_name+"_#{o}_#{typ3}"
                    curb.seek(0)
                    File.open(curb_save_name,"wb")<<curb.read(curb.size)
                    curb.seek(0)

                    #save txt
                    if typ3 == "KEYS"
                        curb_txt=par_dv_curv_txt(curb)
                        File.open(curb_save_name+".txt","wb") do |ws|
                            for p in 0...curb_txt.size
                                curb_chi=curb_txt[p]
                                ws<<curb_chi.join(",")+"\n"
                            end
                        end
                    end
                end
            end
        end
    end
}
elis.close
