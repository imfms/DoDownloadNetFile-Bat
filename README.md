`V0.1` `20161204`
# DoDownloadNetFile-Bat
> 根据配置文件从指定URL下载数据并根据配置文件作相应操作

##配置模式列表
配置描述

- `URL` 下载地址 *必填*
- `TARGET_DIR` 下载路径,如未指定或指定不存在则默认目标路径为"%temp%\tmp_%random%%random8%.exe"
- `IS_RUN` 下载完毕后是否执行, *true: 是*, *false: 否*, 默认*false*
- `RUN_DELAY` 下载完毕后执行延时, 此项需要`IS_RUN`开启状态，默认为0/s

### 1.代码定义
在代码头部指示区域进行变量定义

### 2.参数传入
- `%1` - `URL`
- `%2` - `TARGET_DIR`
- `%3` - `IS_RUN`
- `%4` - ` RUN_DELAY`

### 1.配置文件

> 批处理当前目录下`%bat文件基本名(不包含扩展名)%.ini`

> e.g. DoDownloadNetFile.bat -> DoDownloadNetFile.ini

以制表符为分隔符的properties属性文件读取

- `URL` - `URL`
- `TARGET_DIR` - `TARGET_DIR`
- `IS_RUN` - `IS_RUN`
- `RUN_DELAY` - `RUN_DELAY`

> e.g.

> URL	http://www.baidu.com/logo.png

## 执行参数错误的处理动作
- 遇到必要错误立即停止, e.g. URL未填写

## 相关链接
- 文本数据库工具: [TextDatabase-Bat](https://github.com/imfms/TextDatabase-Bat)