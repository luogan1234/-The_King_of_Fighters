#include <opencv2\core\core.hpp>
#include <opencv2\highgui\highgui.hpp>
#include <cstdio>
#include <string>
using namespace std;
#include <iostream>
#include <fstream>

cv::Mat picture;
ofstream fout("picture.mif");
ofstream fout2("address.txt");
ofstream data("data",ios::binary);

cv::Mat image(1000,1000,CV_8UC3,cvScalar(0,0,0));
int sss;
bool p[1024];

void drawpixel(int x,int y,cv::Vec3b &color)
{
	image.at<cv::Vec3b>(y,x)=color;
}

int main()
{
	int t,i,j,k,n,m,a,b,c,o;string s;char ss[10];
	int address=0;
	for (t=0;t<28;++t)
	{
		sprintf(ss, "%d.bmp", t);s=ss;
		cout<<s<<endl;
		picture=cv::imread(s);
		n=picture.rows;m=picture.cols;
		fout2<<t<<':'<<address<<endl;
		o=0;k=0;int tot=0;sss=1;
		while (sss<m) sss*=2;cout<<sss<<endl;
		fout2<<sss<<endl;
		for (i=0;i<n;++i) for (j=0;j<sss;++j)
		{
			if (j<m)
			{
				cv::Vec3b pixel=picture.at<cv::Vec3b>(i,j);
				a=pixel[2];b=pixel[1];c=pixel[0];
			}else
			{
				a=b=c=255;
			}
			if (o==0)
				fout<<address<<':';
			if (a==255&&b==255&&c==255&&t>0)
			{
				fout<<"11110011";
				k=k*256+243;
				++o;tot+=8;
//				drawpixel(i,j,cv::Vec3b(255,255,255));
			}
			else
			{
				a/=32;b/=32;c/=64;tot+=8;
				fout<<a/4<<a/2%2<<a%2<<b/4<<b/2%2<<b%2<<c/2<<c%2;
				k=k*256+a*32+b*4+c;p[a*32+b*4+c]=true;
				fout<<a*32+b*4+c<<endl;
				++o;
	//			drawpixel(i,j,cv::Vec3b(c*32,b*32,a*64+32));
			}
			if (o==4)
			{
				for (;tot<32;++tot)
				{
					k=k*2;fout<<'0';
				}
				tot=0;data.write((char*)&k,sizeof(int));k=0;
				o=0;fout<<";\n";++address;
			}
		}
		if (o>0)
		{
			for (;tot<32;++tot)
			{
				k=k*2;fout<<'0';
			}
			tot=0;data.write((char*)&k,sizeof(int));k=0;
			o=0;fout<<";\n";++address;
		}
	}
	fout.close();
//	cv::imwrite("test.bmp",image);
}
