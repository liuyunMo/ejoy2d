-- It's a simple sprite package warpper, use your own asset format instead.

local ejoy2d = require "ejoy2d"
local ppm = require "ejoy2d.ppm"
local pack = require "ejoy2d.spritepack"
local sprite = require "ejoy2d.sprite"

-- This limit defined in texture.c
local MAX_TEXTURE = 128

local textures = {}
local packages = {}

local spack = {}
local package_pattern

local function require_tex(filename)
	local tex = #textures
	assert(tex < MAX_TEXTURE)
	table.insert(textures, filename)
	ppm.texture(tex,filename)
	return tex
end

function spack.path(pattern)
	package_pattern = pattern
end

local function realname(filename)
	assert(package_pattern, "Need a pattern")
	return string.gsub(package_pattern,"([^?]*)?([^?]*)","%1"..filename.."%2")
end

function spack.preload(packname)
	if packages[packname] then
		return packages[packname]
	end
	local p = {}
	local filename = realname(packname)
	p.meta = assert(pack.pack(dofile(filename .. ".lua")))
	p.tex = {}
	for i=1,p.meta.texture do
		p.tex[i] = require_tex(filename .. "." .. i)
	end
	pack.init(packname, p.tex, p.meta)
	packages[packname] = p
end

function ejoy2d.sprite(packname, name)
	if packages[packname] == nil then
		spack.preload(packname)
	end
	return sprite.new(packname, name)
end

function spack.load(tbl)
	spack.path(assert(tbl.pattern))
	for _,v in ipairs(tbl) do
		spack.preload(v)
	end
end

function spack.texture(packname, index)
	if packages[packname] == nil then
		spack.preload(packname)
	end
	return packages[packname].tex[index or 1]
end

return spack