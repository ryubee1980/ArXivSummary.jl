module ArXivSummary


using OpenAI
# Write your package code here.

function getGPT(;KEY="OPENAI_API_KEY.txt")

    fn=open(KEY)
        
    line=readline(fn)

    
    secret_key=line
    model = "gpt-3.5-turbo"
    #prompt =  "Say \"this is a test\""
    prompt =  "iphoneとは何ですか？"

    r = create_chat(
        secret_key, 
        model,
        [Dict("role" => "user", "content"=> prompt)]
    )
    println(r.response[:choices][begin][:message][:content])
    #println(r)
end


end
