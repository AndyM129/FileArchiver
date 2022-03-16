# file_archiver.sh

## Introduction

日常开发，备份是个好习惯

但对于动辄几十、成百、上万 个文件的工程，若直接 上传/复制到移动硬盘，效率低到让人怀疑人生

所以先将其打成压缩包，然后再进行备份，无疑可以大大提高执行效率，节省时间，而该工具便应运而生

## Features

通过参数 指定要归档的路径：

* 该工具会判断该路径是否满足归档条件，若满足 则进行归档
* 若不满足，则遍历子文件夹，逐个重复执行上述操作

即，从指定路径开始，递归遍历子文件夹，按需进行归档操作

> 归档：及 打成压缩包，并以 `<文件夹名称>_<时间戳>.zip` 命名

## Usage

1. 查看使用说明

```shell
$ fa
```

![](https://gitee.com/andym129/ImageHosting/raw/master/images/202203161106837.png)

2. 筛查、显示可能的归档处理

> `-d` 表示启用「调试模式」

```shell
$ fa -d . --list
```

![](https://gitee.com/andym129/ImageHosting/raw/master/images/202203161108640.png)

3. 筛查、显示，并执行需要的归档处理

```shell
$ fa -d .
```

![](https://gitee.com/andym129/ImageHosting/raw/master/images/202203161225223.png)

4. 筛查、显示，执行需要的归档处理，并删除被归档的源文件

```shell
$ fa -d . --rof
```

![](https://gitee.com/andym129/ImageHosting/raw/master/images/202203161226274.png)

## Install

> 注：以下内容为针对 MacOS 进行的配置&说明。

为了更便捷的使用该工具，推荐直接安装到本地，即可 像执行系统命令一样的进行备份，具体方法如下。



1. 打开`~/.bashrc`文件，并追加如下代码

  ```shell
  ##############################【Backup】#################################
  alias fa.install='install_path="/Users/$USER/.bash_files/FileArchiver"; git_url="https://github.com/AndyM129/FileArchiver.git"; rm -rf "$install_path"; git clone $git_url $install_path; echo "script_tpl.sh install success: $install_path"; open $install_path;'
  alias fa.opendir='open /Users/$USER/.bash_files/FileArchiver'
  ```

2. 执行如下命令，以便让修改生效

   ```shell
   source ~/.bashrc # 可在任意目录下执行
   ```

3. 安装

   ```shell
   fa.install # 可在任意目录下执行
   ```

4. 完成





## UpdateLog

### 2022/03/15: v1.0.0
* 实现核心功能开发，包括：目录的递归遍历、工程文件的识别&归档、彩色日志的输出
* 支持参数控制 以删除被归档的源文件
* 补充使用说明 及文档


## Author

AndyMeng, andy_m129@163.com

If you have any question with using it, you can email to me. 



## Collaboration

Feel free to collaborate with ideas, issues and/or pull requests.



## License

FileArchiver is available under the MIT license. See the LICENSE file for more info.



