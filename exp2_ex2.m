clc;
clear;

% 读取音频文件
[y1, fs] = audioread('cut_audio.wav');

% 设置量化参数
quantization_values = 50; % 选择的量化参数
bit_l=[4,6,10];%每个样本点的量化比特数
snr_values = zeros(size(quantization_values));

%归一化音频
max_y=max(abs(y1));
y=y1/max_y;

% 创建子图
figure;

% 绘制原始音频
subplot(length(bit_l)+1, 2, 1);
plot(y1);
title('Original Audio');

% 循环进行编码和解码，比较信噪比
for i = 1:length(bit_l)
    % 编码
    encoded_signal = encode_signal(y, quantization_values,bit_l(i));
    
    % 解码
    decoded_signal = decode_signal(encoded_signal, quantization_values,bit_l(i));
    
    %解码后缩小
    decoded_signal=decoded_signal*max_y;  
    
    % 绘制编码后的音频
    subplot(length(bit_l)+1, 2, i*2+1);
    plot(encoded_signal);
    title(['Encoded Audio (to\_bit = ', num2str(bit_l(i)), ')']);
    
    % 指定文件名
    filename = ['mu-law (mu =50,bit=' num2str(bit_l(i)) ').wav' ];
     
    % 保存WAV文件
    audiowrite(filename, decoded_signal, fs);    
    
    % 绘制解码后的音频
    subplot(length(bit_l)+1, 2, i*2+2);
    plot(decoded_signal);
    title(['Decoded Audio (to\_bit = ', num2str(bit_l(i)), ')']);

    % 计算信噪比
    snr_values(i) = calculateSNR(y1, decoded_signal);

    % 输出信噪比
    fprintf('mu-law SNR values( %.0f bit):',bit_l(i));
    disp(snr_values(i));
end


% 调整子图布局
sgtitle('Mu-law Encoding and Decoding (Parameter=50)');

function output_value = double_to_int_bits(input_value, bits)
    % 输入参数 input_value 是一个64位有符号小数
    % bits 是所需的比特数，可以是4、6或10
    % 返回值 output_value 是一个有符号整数
    
    % 将输入值缩放到目标比特数的范围内
    range = 2^(bits-1) - 1; % 范围为[-range, range]
    scaled_value = input_value * range;
    
    % 四舍五入到最接近的整数
    rounded_value = round(scaled_value);
    
    % 将值转换为整数，并确保其在目标比特数的范围内
    if bits <= 8
        output_value = int8(rounded_value);
    elseif bits <= 16
        output_value = int16(rounded_value);
    end
    
    % 确保值在目标范围内
    if output_value > range - 1
        output_value = range - 1;
    elseif output_value < -range
        output_value = -range;
    end
end


function encoded_signal = encode_signal(input_signal, parameter,y_scale)
    % 执行非均匀量化编码，使用参数 parameter
    % 输入信号 input_signal 是一个列向量或音频信号矩阵
    % 返回编码后的信号 encoded_signal
    
    % 确保输入信号是列向量
    if isrow(input_signal)
        input_signal = input_signal';
    end
    
    % 将输入信号进行量化
    encoded_signal = zeros(size(input_signal));
    for i = 1:size(input_signal, 2)
        % 对每个信道进行量化
        encoded_signal(:, i) = mu_law_quantization(input_signal(:, i), parameter);
    end
    %出来的encoded_signal一定在-1~1范围
    encoded_signal=double_to_int_bits(encoded_signal,y_scale);
end

function output_value = int_to_double_bits(input_value, bits)
    % 输入参数 input_value 是一个有符号整数
    % bits 是所用的比特数，可以是4、6或10
    % 返回值 output_value 是一个64位有符号小数
    
    % 将输入值缩放到目标范围内
    range = 2^(bits-1) - 1; % 范围为[-range, range]
    scaled_value = double(input_value) / range;
    
    % 返回缩放后的值
    output_value = scaled_value;
end

function decoded_signal = decode_signal(encoded_signal, parameter,y_scale)
    % %归一化音频
    % encoded_signal=double(encoded_signal);
    % max_s=max(abs(encoded_signal));
    % encoded_signal=encoded_signal/max_s;
    encoded_signal=int_to_double_bits(encoded_signal,y_scale);
    % 执行非均匀量化解码
    % 输入编码后的信号 encoded_signal 是一个列向量或音频信号矩阵
    % 返回解码后的信号 decoded_signal
    
    % 确保输入信号是列向量
    if isrow(encoded_signal)
        encoded_signal = encoded_signal';
    end
    
    % 对编码后的信号进行解码
    decoded_signal = zeros(size(encoded_signal));
    for i = 1:size(encoded_signal, 2)
        % 对每个信道进行解码
        decoded_signal(:, i) = mu_law_dequantization(encoded_signal(:, i), parameter);
    end
end

function quantized_signal = mu_law_quantization(signal, parameter)
    % Mu-law 非均匀量化编码
    % signal: 输入信号
    % parameter: 量化参数，决定量化级别
    
    % Mu-law 非均匀量化
    quantized_signal = sign(signal) .* log(1 + parameter * abs(signal)) / log(1 + parameter);
end 

function dequantized_signal = mu_law_dequantization(signal, parameter)
    % Mu-law 非均匀量化解码
    % signal: 编码后的信号
    
    % Mu-law 非均匀量化解码
    dequantized_signal = sign(signal) * (1/parameter) .* ((1 + parameter) .^ abs(signal) - 1);
end

function snr = calculateSNR(originalSignal, noisySignal)
    % 计算原始信号的功率
    originalPower = sum(abs(originalSignal).^2) / length(originalSignal);

    % 计算噪声信号的功率
    noisyPower = sum(abs(noisySignal - originalSignal).^2) / length(noisySignal);

    % 计算信噪比（dB）
    snr = 10 * log10(originalPower / noisyPower);
end

