module Word2Vec

# using Base.Collections      # for priority queue
using Base.Cartesian        # for @nexprs
using Distances
# using NumericExtensions
using DataStructures
using StatsFuns


export LinearClassifier, train_one, WordEmbedding, train, accuracy
export save, restore
export find_nearest_words

include("utils.jl")
include("softmax_classifier.jl")
include("tree.jl")
include("word_stream.jl")
include("train.jl")
include("query.jl")

end # module
