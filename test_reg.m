% test.m
len_k=12;
tic
for k =2:len_k
    try
        [~, ~, A]=ecc(stack_bef{k},stack_aft{1}, NoL, NoI, transform, init);
    catch
        [~, ~, A]=ecc(stack_bef{k},stack_aft{1}, NoL, NoI, transform, init);
        disp(['v2 on stack bef ' num2str([a,b])]);
    end
    stack_bef2{k}=imbilatfilt(double(A),DoS);
    try
        [~, ~, ecc_temp1]=ecc(stack_aft{k},stack_aft{1}, NoL, NoI , transform, init);
    catch
        [~, ~, ecc_temp1]=ecc(stack_aft{k},stack_aft{1}, NoL, NoI, transform, init);
        disp(['v2 on stack aft ' num2str([a,b])]);
    end
    %                 [~, ~, ecc_temp2]=ecc(imhistmatch(stack_aft{k}, stack_aft{1}),stack_aft{1}, NoL, NoI, transform, init);
    stack_aft2{k}=imbilatfilt(double(ecc_temp1),DoS);
end
toc


tic
for k =2:len_k
    try
        [A]=dtf_reg(stack_bef{k},stack_aft{1},0,0);
    catch
        [~, ~, A]=ecc(stack_bef{k},stack_aft{1}, NoL, NoI, transform, init);
        disp(['v2 on stack bef ' num2str([a,b])]);
    end
    stack_bef{k}=imbilatfilt(double(abs(ifft2(A))),DoS);
    try
        [ecc_temp1]=dtf_reg(stack_aft{k},stack_aft{1},0,0);
    catch
        [~, ~, ecc_temp1]=ecc(stack_aft{k},stack_aft{1}, NoL, NoI, transform, init);
        disp(['v2 on stack aft ' num2str([a,b])]);
    end
    %                 [~, ~, ecc_temp2]=ecc(imhistmatch(stack_aft{k}, stack_aft{1}),stack_aft{1}, NoL, NoI, transform, init);
    stack_aft{k}=imbilatfilt(double(abs(ifft2(ecc_temp1))),DoS);
end
toc


