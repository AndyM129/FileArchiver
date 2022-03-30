# FileArchiver 文件归档工具

## Introduction

日常开发，备份是个好习惯

但对于动辄包含几十、成百、上万 个文件的工程，若直接「上传云端」或是「复制到移动硬盘」，效率低到让人怀疑人生

所以先将其打成压缩包，然后再进行备份，无疑可以大大提高执行效率，节省时间，而该工具便应运而生

## Features

通过参数 指定要智能归档的路径，然后会从该路径，以及 深入递归遍历其下的子文件，

将符合归档条件的目录进行归档，并支持删除原文件，以此减少总文件数，提高后续的备份效率



核心逻辑如下：

* 该工具执行后，会从命令行传入的路径开始判断：

	* 若是普通文件，则忽略
	* 若当前目录符合归档条件，则对其进行归档操作
	* 若当前目录下没有子目录 则不再遍历其下文件
	* 否则遍历当前目录下的所有子目录，重复上述处理

	

> 1. **归档**：即「打成压缩包」，并以 `<原文件名称>_fa<时间戳>.zip` 命名
>
> 2. **归档条件**：目前的实现，是通过 `find` 命令查找，若该目录下有「IDE配置、Git工程、xcode工程、Flutter工程」特有文件，则会被判定为「符合归档条件」；后续可继续扩展 以支持更多场景
>
> 	```shell
> 	# 若符合「智能归档」条件，则对当前目录进行归档：IDE配置、Git工程、xcode工程、Flutter工程
> 	elif [ $(echo $(find $1 \
> 	    -name ".idea" \
> 	    -o -name ".gitignore" \
> 	    -o -name "LICENSE" \
> 	    -o -name "README.md" -o -name "readme.md" -o -name "README" \
> 	    -o -name "*.git" -o -name "*.gitee" \
> 	    -o -name "*.xcodeproj" -o -name "*.xcplugin" \
> 	    -o -name "pubspec.yaml" \
> 	    -maxdepth 1 | wc -l) | sed 's/ //g') -gt 0 ]; then
> 	    file_archiving "$1"
> 	```



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

### 2022/03/27: v1.3.1
* 智能归档优化：对于需要归档的文件夹，若其更新时间小于 其最近一次归档的时间，则不再重复归档

### 2022/03/27: v1.3.0
* 控制台日志 添加时间显示

### 2022/03/27: v1.2.0
* 支持添加 .faignore 以忽略对应目录

### 2022/03/20: v1.1.0
* 支持智能归档后 备份至指定路径

### 2022/03/20: v1.0.1
* 修复「压缩文件解压后 带有路径」的问题

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



