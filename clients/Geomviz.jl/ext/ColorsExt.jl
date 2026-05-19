module ColorsExt

using Colors
using Pickle

function Pickle.save(p::Pickle.AbstractPickle, io::IO, c::ColorTypes.Colorant)
    c = RGBA(c)
    Pickle.save(p, io, Float64[red(c), green(c), blue(c), alpha(c)])
end

end
