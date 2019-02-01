import Base.iterate

mutable struct WordStream
    fp::IO
    startpoint::Int
    endpoint::Int
    buffer::IOBuffer

    # filter configuration
    rate::Float64   # if rate > 0, words will be subsampled according to distr
    filter::Bool    # if filter is true, only words present in the keys(distr) will be considered
    distr::Dict{String, Float64}
end

function words_of(file::IO; subsampling=(0,false,nothing), startpoint=-1, endpoint=-1)
    rate, filter, distr = subsampling
    WordStream(file, startpoint, endpoint, IOBuffer(), rate, filter, (rate==0 && !filter) ? Dict{String,Float64}() : distr)
end

function iterate(ws::WordStream, state)
    # NEXT / DONE
    while !eof(ws.fp)
        if ws.endpoint >= 0 && position(ws.fp) > ws.endpoint
            break
        end
        c = read(ws.fp, Char)
        if c == ' ' || c == '\n' || c == '\0' || c == '\r'
            s = String(take!(ws.buffer))
            if s == "" || (ws.filter && !haskey(ws.distr, s))
                continue 
            end
            if ws.rate > 0
                prob = (sqrt(ws.distr[s] / ws.rate) + 1) * ws.rate / ws.distr[s]
                if prob < rand()
                    # @printf "throw %s, prob is %f\n" s prob
                    continue
                end
            end
            write(ws.buffer, s)
            return (String(take!(ws.buffer)), state)
        else
            write(ws.buffer, c)
        end
    end
    #close(ws.fp)
    return nothing
end

function iterate(ws::WordStream)
    # START
    if ws.startpoint >= 0
        seek(ws.fp, ws.startpoint)
    else
        ws.startpoint = 0
        ws.endpoint = filesize(ws.fp)
    end

    return iterate(ws, nothing)
end

mutable struct SlidingWindow
    ws::WordStream
    lsize::Int
    rsize::Int
end

function Base.iterate(window::SlidingWindow, state=nothing)
    if state == nothing
        window_size = window.lsize + 1 + window.rsize
        state = Vector{String}(undef, window_size)
        state[1], _ = iterate(window.ws)
        for i = 2:window_size
            state[i], _ = iterate(window.ws, nothing)
        end
    end
    popfirst!(state)
    nextwindow = iterate(window.ws, nothing)
    if nextwindow == nothing
        return nothing
    end
    push!(state, nextwindow[1])
    return (state, state)
end

function sliding_window(words; lsize=5, rsize=5)
    SlidingWindow(words, lsize, rsize)
end
