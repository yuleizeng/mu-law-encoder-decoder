![image](https://github.com/user-attachments/assets/cd502b16-88f4-484d-b6bc-7e55222d253f)​
把我做的实验贴上来了/(ㄒoㄒ)/~~

2.将上述语音信号作  -律非均匀量化编码与解码，并分别采取以下各种不同编解码方案

2.1在64kbps数码率（8kHz采样率，8比特每样本点）条件下，选择5个不同的 值（10-500之间）进行编解码，比较各种编解码语音和原始语音的质量（信噪比）

2.1.1原理

1.均匀量化

对编码范围内小信号或大信号都采用等量化级进行量化 ,因此小信号的“信号与量化噪声比”小 ,而大信号的“信号与量化噪声比”大 ,这对小信号来说是不利的。为了提高小信号的信噪比 ,可以将量化级再细分些 ,这时大信号的信噪比也同样提高 ,但这样做的结果使数码率也随之提高 ,将要求用频带更宽的信道来传输。

对于16位的音频数据降低至8位，直接将数据右移8位，即将数据除以2^8，这样会使得声音的噪音变大。

2.非均匀量化

对于均匀量化存在的问题则采样非均匀量化解决。它的基本思想是对大信号进行压缩而对小信号进行较大的放大。由于小信号的幅度得到较大的放大 ,从而使小信号的信噪比大为改善。目前常用的压扩方法是对数型的 A律压缩和 μ律压缩 ,其中 μ律压缩公式：

y=ln(1+μx)/ln(1+μ）

其中 x 为归一化的量化器输入 , y 为归一化的量化器输出。常数 μ愈大 ,则小信号的压扩效益愈高 ,目前多采用 μ= 255。

其中μ255 /15折线压缩特性曲线如图 1所示：

![image](https://github.com/user-attachments/assets/c5fa1f11-44c2-4d31-b517-f87b239c2ca5)


2.1.2实验思考

（1）要求得到8比特每样本点，说明需要将得到的编码后的信息强制转化成8bit的信息，我的音频输入信号是8bytes，64bit的

![image](https://github.com/user-attachments/assets/7c0a6994-dcf4-4a6c-8acc-b4cf7e822d11)


（2）解码需要对编码公式进行反推导，主要是网上公式和PPT公式有点不一样，是归一化部分不一样，所以需要重新推导。PPT里面的公式![image](https://github.com/user-attachments/assets/85b1da8d-6e04-4ee9-8d70-f8b361fe00fc)
加了Xmax,是为了归一化输入信号。为了方便我的代码实现，我使用的公式如下：

①µ律压扩

encoded\_signal= \frac{ln(1+\mu \left | x(n) \right | )}{ln(1+\mu )} sgn[x(n)]


![image](https://github.com/user-attachments/assets/6ed33423-bfa5-4825-9854-4f03bba44bc1)



代码实现
![image](https://github.com/user-attachments/assets/82246872-5eb1-4ceb-99b4-d2e3062f23b6)



②µ律压扩反变换

decoded\_signal= \frac{1}{\mu }\times  ((1+\mu)^{\left |y\right | } -1)\times  sgn[x(n)]

![image](https://github.com/user-attachments/assets/ecaa396a-03d1-46ca-8378-67ad44cc7d1e)


代码实现

![image](https://github.com/user-attachments/assets/84713eab-f4cd-4cbd-8259-4a6d61733360)


（3）我的输入音频幅度值在-0.2466-0.2868范围内，小于-1~1范围内额，所以在 -律非均匀量化编前不需要缩小到-1~1之间。但是为了使后面的音频变化更加明显，我还是对原始信号进行幅度的扩大到-1~1范围。我用输入音频除以其绝对值的最大值实现归一化，如下

![image](https://github.com/user-attachments/assets/a099a29c-5b54-4b06-83d6-e6b98cf55647)


然后保存下这个最大值，方便后面对解码信号进行归一化的逆变换，即

![image](https://github.com/user-attachments/assets/0fd704b5-04c2-4b37-a652-704afd4736b0)


资料查到：Mu-law变换通常应用于音频信号的数字化过程中，而音频信号的幅度范围通常是有限的，例如在16位PCM音频中，幅度范围通常在-32768到32767之间。如果输入信号的幅度超出了这个范围，进行Mu-law变换时可能会出现截断或溢出等问题，导致失真。因此，归一化可以确保输入信号的幅度范围在Mu-law变换能够处理的范围内，以避免这些问题的发生。
![image](https://github.com/user-attachments/assets/be80e40a-a122-4608-953c-808f8cf42ad6)



（4）对于8bit量化处理

因为输入的编码信号时是-1~1之间的小数，64bit的double类型小数。对小数进行Mu-law变换后的数字范围还是在-1~1之间，下面这个图可以很清晰表示



所以对于8bit，我把小数转化到-128~127之间的int8类型得到编码后的信号，此时传输出去的编码信号就是8bit的了。当接收设备得到编码后的信号，需要把编码信号按照预定的8bit规则转化到-1~1之间的64bit的double类型。然后再进行Mu-law反变换。

（5）对于信噪比计算，一开始用的snr函数输出得到的信噪比都在0.003那么小，后面发现是计算信噪比的时候计算成原始信号和解码信号的比。应该是计算信号和噪声的比才对。

![image](https://github.com/user-attachments/assets/5a2e231f-fdf2-4a7c-a053-3c8c8f47a842)



2.1.3结果

（1）编码解码后的信号结果

左侧是编码后信号，右侧是解码后的信号。每一行表示不同的μ值。第一个子图是原始信号。肉眼看虽然不同μ值编码解码后的信号长得差不都，实际计算出的信噪比是有区别的。

![image](https://github.com/user-attachments/assets/8a36cf24-643d-4e3c-9bac-361dc5bf29f2)



（2）信噪比计算结果

可以发现我的音频，随着 值的增大，SNR值是降低的，即信号编解码性能越来越差


![image](https://github.com/user-attachments/assets/1df4622e-6533-4c0a-a890-a0a3d8145b9a)


2.2在 条件下，采样率仍为8kHz，改变每个样本点的量化比特数为4，6和10比特三种不同情况下，比较各个解码后语音的质量(信噪比)。

2.2.1实验过程

一开始设计double转化成规定量化比特数的时候，最后的传输没有用固定用了int8，导致量化10bit的时候，大于8bit，超出了计算机uint8范围。后来修改成判断语句了：



![image](https://github.com/user-attachments/assets/33ca34dc-36de-4c77-a4d4-f8f7560aa975)

下面是错误结果：


![image](https://github.com/user-attachments/assets/0260cc84-0b54-4073-a7c6-50f2d46001d0)


![image](https://github.com/user-attachments/assets/275a3dfa-0619-4e58-a745-8ecb679cdb53)



2.2.2实验结果

下面是修改代码后的正确结果

（1）左侧是编码后信号，右侧是解码后的信号。每一行表示不同的bit量化值。第一个子图是原始信号。可以看到4bit的量化编码信号类似于马赛克，是因为数据传输精度低，导致有信息损失。解码马赛克形状是因为，编码后的信息损失恢复不回来了。10bit量化的编解码结果肉眼看起来和原始信号没有什么区别，虽然原始信号是64bit编码。

![image](https://github.com/user-attachments/assets/dc18bfb4-3de9-4e98-948c-b98293d50f59)


![image](https://github.com/user-attachments/assets/39bb6c4e-55db-48c9-beed-6cbfd4598f10)




​
