module ArXivSummary


using OpenAI
using HTTP:request
using LightXML
# Write your package code here.


function getArXiv(;max=2)
    ARXIV_QUERY = "%28cat:cond-mat.soft+OR+cat:cond-mat.stat-mech+OR+cat:physics.chem-ph%29+AND+%28ti:ion+OR+ti:salt+OR+ti:electrolyte+OR+abs:ion+OR+abs:salt+OR+abs:electrolyte%29"
    # Here, "+", "%28", and "%29" respectively denote the space " ", left parentheses "(", and right parentheses ")" in the url format.
    MAX_PAPER_COUNT = max
    ARXIV_API_URL = "http://export.arxiv.org/api/query"
    ARXIV_TERM = 3

    #url = "$(ARXIV_API_URL)?search_query=$(ARXIV_QUERY)&sortBy=lastUpdatedDate&sortOrder=descending&max_results=$(MAX_PAPER_COUNT)&start=0&submitted_date[from]=${toYYYYMMDD(date)}&submitted_date[to]=${toYYYYMMDD(date)}"

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
    date="Date:"
    date*=content(ext[1])

    title,authors[1:end-3],summary,id,date
end


function main(;max=2)
    entries=getArXiv(max=max)
    num=length(entries)
    title=Array{String}(undef,num)
    authors=similar(title)
    summary=similar(title)
    id=similar(title)
    gpt=similar(title)
    date=similar(title)
    for i in 1:num
        title[i],authors[i],summary[i],id[i],date[i]=extract_data(entries[i])
        #gpt[i]=getGPT(title[i],summary[i])
        println(date[i])
        println(title[i])
        println(authors[i])
        #println(summary[i])
        #println(gpt[i])
        println(id[i])
    end
    
end

function getGPT(title,summary;KEY="OPENAI_API_KEY.txt")

    fn=open(KEY)
        
    line=readline(fn)

    
    secret_key=line
    model = "gpt-3.5-turbo"
    #prompt =  "Say \"this is a test\""
    prompt =  "あなたは統計物理，化学物理，ソフトマター物理に精通した研究者で、論文を簡潔に要約することに優れています。以下の論文を、タイトルと要約の2点をそれぞれ改行で分けて日本語で説明してください。要約は箇条書きで4-8行程度にまとめること。$(title) $(summary)"

    r = create_chat(
        secret_key, 
        model,
        [Dict("role" => "user", "content"=> prompt)]
    )
    r.response[:choices][begin][:message][:content]
   
    #typeof(r.response[:choices][begin][:message][:content])
end


end
