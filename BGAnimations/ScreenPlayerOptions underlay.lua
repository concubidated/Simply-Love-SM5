-- Quad at the bottom of the screen behind the explanation of the current OptionRow.
return Def.Quad{
	Name="ExplanationBackground",
	InitCommand=function(self)
		self:diffuse(0,0,0,0)
		:horizalign(left):vertalign(top)
		:setsize(WideScale(598,792), 40)
		:xy(WideScale(20,30), _screen.h-50)
	end,
	OnCommand=function(self) self:linear(0.2):diffusealpha( BrighterOptionRows() and 0.9 or 0.8 ) end,
}