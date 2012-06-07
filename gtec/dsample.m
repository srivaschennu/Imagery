function data = dsample(data,dsfactor)

chancount = size(data,1);
epochcount = size(data,3);

downdata = zeros(size(data,1),size(data,2)/dsfactor,size(data,3));

for channel = 1:chancount
    for epoch = 1:epochcount
        downdata(channel,:,epoch) = downsample(squeeze(data(channel,:,epoch)),dsfactor);
    end
end
data = downdata;