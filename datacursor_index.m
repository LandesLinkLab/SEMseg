function txt = datacursor_index(obj,evnt)
%datacursor_index Includes the index in the data cursor
    pos = get(evnt,'Position');
    I = get(evnt,'DataIndex');
    txt = {['X: ',num2str(pos(1))],...
           ['Y: ',num2str(pos(2))],...
           ['I: ',num2str(I)]};
end

