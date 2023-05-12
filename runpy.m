function n_commands=runpy(t,filename)
fid=fopen(filename,'r');
data=importdata(filename);
if isstruct(data)
    commands=data.textdata;
else
    commands=data;
end
% indents=regexp(commands,':');
% which_indents=find(~cellfun(@isempty,indents));
% statement_range=[];
% for in=which_indents(:)'
%     if any(indents{in}==length(commands{in}))
%         %true indent
%         cur_in=in+1;
%         while 1
%             if cur_in==length(commands)
%                 break;
%             end
%             findspaces=regexp(commands{cur_in},' ');
%             endofindent=find(diff(findspaces)==1,1,'last')+1;
%             if isempty(endofindent) || ~any(findspaces==1)
%                 cur_in=cur_in-1;
%                 break;
%             end
%             cur_in=cur_in+1;
%         end
%         statement_range=[statement_range;in cur_in];
%     end
% end
% for n=1:length(commands)
%     find_statement=statement_range(:,1)==n;
%     if any(find_statement)
%         statement_range_cur=statement_range(find_statement,:);
%     else
%         statement_range_cur=n;
%     end
%     cur_command=commands(statement_range_cur(1):statement_range_cur(end));
%     if length(cur_command)>1
%         cur_command=cat(2,cur_command,repmat({char([uint8(13) uint8(10)])},diff(statement_range_cur)+1,1));
%         cur_command=cur_command();
%         cur_command=strcat(cur_command{1:end-1});
%     else
%         cur_command=cur_command{1};
%     end
%     write(t,cur_command,'char');
%     n=statement_range_cur(end);
% end
n_commands=numel(commands);
cur_command=cat(2,commands,repmat({char([uint8(13) uint8(10)])},length(commands),1))';
cur_command=cat(2,cur_command{1:end-1});
write(t,cur_command,'char');
fclose(fid);