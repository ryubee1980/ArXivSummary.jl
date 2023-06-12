using ArXivSummary
using Test

@testset "ArXivSummary.jl" begin
    ArXivSummary.main() |> ArXivSummary.write_result 
end
