function TD = convert(TDin)
%this function converts from the old ".Xaddress .Yaddress" format to the
%new ".x .y" format
TD{x,y}.x = TDin{x,y}.Xaddress;
TD{x,y}.y = TDin{x,y}.Yaddress;
TD{x,y}.ts = TDin{x,y}.TimeStamp;
nums = unique(TDin{x,y}.Polarity);
TD{x,y}.p = TDin{x,y}.Polarity;
for i = 1:length(nums)
    TD{x,y}.p(TDin{x,y}.Polarity == unique(i)) = i;
end
