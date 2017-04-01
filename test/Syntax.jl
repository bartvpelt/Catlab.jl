""" Test the Syntax module.

The unit tests are sparse because many of the Doctrine tests are really just
tests of the Syntax module.
"""
module TestSyntax

using Base.Test
using CompCat.GAT
using CompCat.Syntax

# Syntax
########

# Simple case: Monoid (no dependent types)

@signature Monoid(M) begin
  M::TYPE
  munit()::M
  mtimes(x::M,y::M)::M
end

@syntax FreeMonoid Monoid
@test isa(FreeMonoid, Module)
@test sort(names(FreeMonoid)) == sort([:FreeMonoid, :M])

x, y, z = FreeMonoid.m(:x), FreeMonoid.m(:y), FreeMonoid.m(:z)
@test x == FreeMonoid.m(:x)
@test x != y
@test isa(mtimes(x,y), FreeMonoid.M)
@test isa(munit(FreeMonoid.M), FreeMonoid.M)
@test mtimes(mtimes(x,y),z) != mtimes(x,mtimes(y,z))

@syntax FreeMonoidAssoc Monoid begin
  mtimes(x::M, y::M) = associate(FreeMonoidAssoc.mtimes(x,y))
end

x, y, z = FreeMonoidAssoc.m(:x), FreeMonoidAssoc.m(:y), FreeMonoidAssoc.m(:z)
e = munit(FreeMonoidAssoc.M)
@test mtimes(mtimes(x,y),z) == mtimes(x,mtimes(y,z))
@test mtimes(e,x) != x && mtimes(x,e) != x

@syntax FreeMonoidAssocUnit Monoid begin
  mtimes(x::M, y::M) = associate(:munit, FreeMonoidAssocUnit.mtimes(x,y))
end

x, y, z = FreeMonoidAssocUnit.m(:x), FreeMonoidAssocUnit.m(:y), FreeMonoidAssocUnit.m(:z)
e = munit(FreeMonoidAssocUnit.M)
@test mtimes(mtimes(x,y),z) == mtimes(x,mtimes(y,z))
@test mtimes(e,x) == x && mtimes(x,e) == x

# Category (includes dependent types)

@signature Category(Ob,Hom) begin
  Ob::TYPE
  Hom(dom::Ob, codom::Ob)::TYPE
  
  id(X::Ob)::Hom(X,X)
  compose(f::Hom(X,Y), g::Hom(Y,Z))::Hom(X,Z) <= (X::Ob, Y::Ob, Z::Ob)
  
  compose(fs::Vararg{Hom}) = foldl(compose, fs)
end

@syntax FreeCategory Category begin
  compose(f::Hom, g::Hom) = associate(FreeCategory.compose(f,g))
end

@test isa(FreeCategory, Module)
@test sort(names(FreeCategory)) == sort([:FreeCategory, :Ob, :Hom])

X, Y, Z, W = map(FreeCategory.ob, [:X, :Y, :Z, :W])
f = FreeCategory.hom(:f, X, Y)
g = FreeCategory.hom(:g, Y, Z)
h = FreeCategory.hom(:h, Z, W)
@test isa(X, FreeCategory.Ob) && isa(f, FreeCategory.Hom)
@test_throws MethodError FreeCategory.hom(:f)
#@test dom(f) == X && codom(f) == Y

@test isa(id(X), FreeCategory.Hom)
#@test dom(id(X)) == X && codom(id(X)) == X

@test isa(compose(f,g), FreeCategory.Hom)
@test compose(compose(f,g),h) == compose(f,compose(g,h))
@test compose(f,g,h) == compose(compose(f,g),h)

# Pretty-print
##############

A, B = FreeCategory.ob(:A), FreeCategory.ob(:B)
f, g, = FreeCategory.hom(:f, A, B), FreeCategory.hom(:g, B, A)

# S-expressions
sexpr(expr::BaseExpr) = sprint(show_sexpr, expr)

@test sexpr(A) == ":A"
@test sexpr(f) == ":f"
@test sexpr(compose(f,g)) == "(compose :f :g)"
@test sexpr(compose(f,g,f)) == "(compose :f :g :f)"

end
