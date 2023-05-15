function strings_out=commandify(strings)
if ~isstring(strings)
    strings=string(strings);
end
strings=deblank(strings);
n_commands=size(strings,1);
strings_out=strings+repmat("\n",n_commands,1);
