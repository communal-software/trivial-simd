#include <assert.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
typedef int (*kernel)(int,int64_t,int64_t,int64_t,const uint16_t*,int64_t,const float*,int64_t,float*,int64_t);
static double seconds(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec + t.tv_nsec * 1e-9; }
static double batch(kernel fn,int f16,int64_t m,int64_t k,uint16_t*w,float*x,float*out,int iterations) {
    double start=seconds();
    for(int i=0;i<iterations;i++) assert(!fn(f16,1,m,k,w,k,x,k,out,m));
    return seconds()-start;
}
int main(int argc,char**argv) {
    assert(argc==2);
    int widths[]={0,1}; kernel functions[2];
    for(int i=0;i<2;i++) { char path[1024];snprintf(path,sizeof path,"%s/tile-%d.dylib",argv[1],widths[i]);void*lib=dlopen(path,RTLD_NOW|RTLD_LOCAL);assert(lib);functions[i]=(kernel)dlsym(lib,"ts_encoded_matmul");assert(functions[i]); }
    int64_t shapes[][2]={{3072,1024},{1024,3072},{1024,1024},{1024,2048},{2048,1024},{151936,1024},{8192,2048},{2048,8192},{128256,2048}};
    puts("round,variant,encoding,outputs,inputs,milliseconds");
    for(unsigned s=0;s<sizeof shapes/sizeof*shapes;s++) {
        int64_t m=shapes[s][0],k=shapes[s][1];uint16_t*w=malloc(m*k*2);float*x=malloc(k*4),*out=malloc(m*4),*reference=malloc(m*4);assert(w&&x&&out&&reference);
        for(int64_t i=0;i<k;i++)x[i]=(float)((int)(i%19)-9)/16;
        for(int f16=0;f16<=1;f16++) {
            for(int64_t i=0;i<m*k;i++)w[i]=(uint16_t)((f16?0x3000:0x3b00)+(i%1024));
            assert(!functions[0](f16,1,m,k,w,k,x,k,reference,m));
            for(int i=0;i<2;i++){assert(!functions[i](f16,1,m,k,w,k,x,k,out,m));assert(!memcmp(out,reference,m*4));}
            for(int round=0;round<5;round++)for(int order=0;order<2;order++) {
                int index=(round+order)%2,iterations=1;double samples[3];
                while(batch(functions[index],f16,m,k,w,x,out,iterations)<0.02)iterations*=2;
                for(int i=0;i<3;i++)samples[i]=batch(functions[index],f16,m,k,w,x,out,iterations)*1000/iterations;
                for(int i=0;i<3;i++)for(int j=i+1;j<3;j++)if(samples[j]<samples[i]){double t=samples[i];samples[i]=samples[j];samples[j]=t;}
                printf("%d,%s,%s,%lld,%lld,%.6f\n",round+1,index?"after":"before",f16?"f16":"bf16",(long long)m,(long long)k,samples[1]);fflush(stdout);
            }
        }
        free(reference);free(out);free(x);free(w);
    }
}
