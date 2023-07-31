module ArXivSummary


using OpenAI
using HTTP:request
using LightXML
using Dates
# Write your package code here.


function getArXiv(;max=2,query="query_ion.txt")
    fn=open(query,"r")
        
    line=readline(fn)

    close(fn)
    ARXIV_QUERY = line
    # Here, "+", "%28", and "%29" respectively denote the space " ", left parentheses "(", and right parentheses ")" in the url format.
    MAX_PAPER_COUNT = max
    ARXIV_API_URL = "http://export.arxiv.org/api/query"
    

    url = "$(ARXIV_API_URL)?search_query=$(ARXIV_QUERY)&sortBy=lastUpdatedDate&max_results=$(MAX_PAPER_COUNT)"

    r=request(:GET,url)
 
    xml_string=parse_string(String(r.body))
    xml=root(xml_string)
    
    entries=get_elements_by_tagname(xml,"entry")
end

function extract_data(entries_element)
    ext=get_elements_by_tagname(entries_element,"title")
    title="Title: "
    title*=content(ext[1])

    ext=get_elements_by_tagname(entries_element,"author")
    ext2=get_elements_by_tagname.(ext,"name")
    authors="Author(s): "
    for a in ext2, b in a
        authors=authors*content(b)*", "
    end

    ext=get_elements_by_tagname(entries_element,"summary")
    summary="Summary:"
    summary*=content(ext[1])

    ext=get_elements_by_tagname(entries_element,"id")
    id="URL: "
    id*=content(ext[1])

    ext=get_elements_by_tagname(entries_element,"published")
    date="1st Publication Date:"
    date*=content(ext[1])

    title,authors[1:end-3],summary,id,date
end

function getGPT(title,summary;KEY="OPENAI_API_KEY.txt")

    fn=open(KEY,"r")
        
    line=readline(fn)

    close(fn)

    
    secret_key=line
    model = "gpt-3.5-turbo"
    #prompt =  "Say \"this is a test\""
    #prompt =  "あなたは統計物理，化学物理，ソフトマター物理に精通した研究者で、論文を簡潔に要約することに優れています。以下の論文を、タイトルと要約の2点をそれぞれ改行で分けて日本語で説明してください。要約は箇条書きで4-8行程度にまとめること。$(title) $(summary)"

    prompt =  "You are a theoretical physicist having deep understanding of statistical physics, softmatter physics, chemical physics, and quantum field theory. The following title and abstract are taken from a paper that I want to understand. \n title: $(title) \n abstract: $(summary) \n Please summarize the abstract into itemized form of 4-8 lines and translate the title and the summary into Japanese."

    r = create_chat(
        secret_key, 
        model,
        [Dict("role" => "user", "content"=> prompt)]
    )
    r.response[:choices][begin][:message][:content]
   
    #typeof(r.response[:choices][begin][:message][:content])
end


function main(;max=2,query="query_ion.txt",T_int=4)
    entries=getArXiv(max=max,query=query)
    num=length(entries)
    title=Array{String}(undef,num)
    authors=similar(title)
    summary=similar(title)
    id=similar(title)
    gpt=similar(title)
    date=similar(title)
    for i in 1:num
        title[i],authors[i],summary[i],id[i],date[i]=extract_data(entries[i])
        gpt[i]=getGPT(title[i],summary[i])
        sleep(T_int)
        #println(date[i])
        #println(title[i])
        #println(authors[i])
        #println(summary[i])
        #println(gpt[i])
        #println(id[i])
    end
    [date title authors gpt id]
end

function write_result(list;file="Ion",output_latest="yes")
    num=length(list[:,1])
    month=Dates.format(now(),"mm")
    year=Dates.format(now(),"yyyy")
    date=today()
    if !isdir("$(year)")
        mkdir("$(year)")
    end
    fn=open("./$(year)/$(file)$(month).txt","a")
    println(fn,"************************")
    println(fn,"* 取得年月日: $(date) *")
    println(fn,"************************")
    println(fn,"\n\n") 
    for i in 1:num
        for j in 1:3
            println(fn,list[i,j])
        end  
        println(fn,"\n")
        println(fn,list[i,4])
        println(fn,"\n")
        println(fn,list[i,5])
        println(fn,"\n-------------------------------------------------------------------------------\n\n")
    end
    close(fn)

    if output_latest=="yes"
        if !isdir("latest")
            mkdir("latest")
        end
        fn=open("./latest/$(file)_latest.txt","w")
        println(fn,"************************")
        println(fn,"*    LATEST            *")
        println(fn,"* 取得年月日: $(date) *")
        println(fn,"************************")
        println(fn,"\n\n") 
        for i in 1:num
            for j in 1:3
                println(fn,list[i,j])
            end  
            println(fn,"\n")
            println(fn,list[i,4])
            println(fn,"\n")
            println(fn,list[i,5])
            println(fn,"\n-------------------------------------------------------------------------------\n\n")
        end
        close(fn)
    end
end

end
