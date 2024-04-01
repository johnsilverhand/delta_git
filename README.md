
- [环境搭建](#环境搭建)
- [项目介绍](#项目介绍)
- [代码框架](#代码框架)
  - [代码框架各文件简要说明](#代码框架各文件简要说明)
    - [main.c](#mainc)
    - [cmd.c/.h](#cmdch)
    - [utils](#utils)
      - [file.c/.h](#filech)
      - [dir.c/.h](#dirch)
      - [list.c/.h](#listch)
      - [std.h](#stdh)
- [dg版本控制的实现原理](#dg版本控制的实现原理)
  - [.dg文件夹结构](#dg文件夹结构)
  - [基本数据结构的定义](#基本数据结构的定义)
    - [文件副本](#文件副本)
    - [版本tree](#版本tree)
    - [提交commit](#提交commit)
    - [索引index](#索引index)
    - [HEAD](#head)
  - [实现过程](#实现过程)
    - [初始化版本库](#初始化版本库)
    - [添加文件到索引区](#添加文件到索引区)
    - [提交索引区的文件到版本库](#提交索引区的文件到版本库)
    - [恢复版本](#恢复版本)
    - [打印提交记录](#打印提交记录)
    - [删除文件](#删除文件)

# 环境搭建
环境配置如下：
- 操作系统：Ubuntu 18.04
- 编译器：gcc
- 编译工具：make
- 编辑器：vim & vscode
- 语言：C
在终端输入如下命令进行编译得到可执行程序 *dg*：
```bash
sudo make
```
# 项目介绍
 dg(delta git)项目的目的是实现一个简易的git, 用于管理代码版本。项目的主要功能如下：
- 创建版本
- 恢复版本

实现的git命令如下：
- dg init
- dg add
- dg rm
- dg commit
- dg checkout
- dg log

项目实现的基本原理如下：
1. 以文件为粒度的版本控制
- 对某个文件进行修改，提交形成一个新版本
- 新版本
- - 记录修改后文件的全部内容
- - 而不是记录新版本相对老版本的差异
 
2. 在不同的版本之间共享文件
- 计算每个文件的 ID

- - 两个文件的内容相同，则这两个文件的 ID 相同
- - 两个文件的内容不同，则这两个文件的 ID 不同
- 实现共享

- - 版本由多条记录构成
- - 记录由两个字段构成：文件的名称和文件的 ID

# 代码框架
代码存放在 `src` 文件夹中,目录结构如下：
```
├── cmd.c
├── cmd.h
├── main.c
├── Makefile
└── utils
    ├── dir.c
    ├── dir.h
    ├── file.c
    ├── file.h
    ├── list.c
    ├── list.h
    └── std.h
```
## 代码框架各文件简要说明
### main.c
主控模块，解析命令行参数，调用相应的函数，响应的函数在 `cmd.c` 中实现。
### cmd.c/.h
使用的头文件如下：
```c
#include "utils/std.h"
#include "utils/file.h"
#include "utils/dir.h"
#include "utils/list.h"
#include "cmd.h"
```
实现了git命令的功能，包括：
- dg init

    函数接口为 `void init()`
- dg add

    函数接口为 `void add(const char *path)`

    命令 add arg 带有一个参数 path，path 可以是文件或目录

        如果 arg 是文件，则把单个文件加入到索引区
        如果 arg 是目录，则把目录下的所有文件加入到索引区

- dg rm

    函数接口为 `void rm(const char *path)`

    命令 rm arg 带有一个参数 path, path 可以是文件或目录

        如果 arg 是文件，则从索引区中删除单个文件
        如果 arg 是目录，则从索引区中删除目录下的所有文件
- dg commit

    函数接口为 `void commit(const char *message)`
    
    命令 commit 提交索引区中的文件到版本库
- dg checkout

    函数接口为 `void checkout(const char *commit_id)`

    命令 checkout 恢复指定的版本到工作目录下

- dg log

    函数接口为 `void log()`
    
    命令 log 打印提交记录
-  usage

    函数接口为 `void usage()`
    
    主函数没接收到命令行参数时打印使用说明

### utils
存放一些工具函数，包括：
#### file.c/.h

文件操作函数，包括读写文件，获取文件大小等
    
宏定义如下：
```c
#define LINE_SIZE 128
```

函数接口如下：
```c
//从已经打开的文件中读取一行，会删除行末尾的换行
extern int read_line(FILE *f, char *line);
//向已经打开的文件中写入一行，会在行末尾添加换行
extern void write_line(FILE *f, char *line);
//根据文件路径名，调用 read_line 读取一行会删除行末尾的换行
extern int load_line(char *path, char *line);
//根据文件路径名，调用 write_line 写入一行会在行末尾添加换行
extern void store_line(char *path, char *line);

//判断文件是否是目录
extern bool file_is_dir(char *path);
//判断文件是否存在
extern bool file_exists(char *path);
//获取文件长度
extern int get_file_size(char *path);
//根据文件路径名和内容创建文件
extern void make_file(char *path, char *content);
//复制文件
extern void copy_file(char *source_path, char *target_path);

```

#### dir.c/.h
    
目录操作函数，包括创建目录，遍历目录等

头文件中定义的结构体如下：
```c
typedef struct {
    int type;
    char name[NAME_MAX];
    char path[PATH_MAX];
} entry_t;

typedef struct {
    char base[PATH_MAX];
    DIR *fd;
} dir_t;
```
定义的函数接口如下：
```c
//判断 entry 是否是一个普通文件
extern int entry_is_regular(entry_t *this);
//判断 entry 是否是一个目录
extern int entry_is_dir(entry_t *this);

//打开目录
extern dir_t *dir_open(char *path);
//读取目录,返回值为 0 时表示读取结束
extern int dir_read(dir_t *this, entry_t *entry);
//关闭目录
extern void dir_close(dir_t *this);
```

下面是一段使用上述函数的示例代码和程序输出：
```c
void list_dir(char *path)
{
    dir_t *dir = dir_open(path);
    entry_t entry;
    while (dir_read(dir, &entry))
        printf("%s\n", entry->path);
    dir_close(dir);
}

int main(int argc, char *argv[])
{
    list_dir("dir");
    list_dir(".");
    return 0;
}
```
输出如下：
```bash
dir/x
dir/y
dir/z
a
b
c
dir
```

#### list.c/.h
    
链表操作函数，包括链表的创建，插入，删除等

文件中的结构体定义如下：
```c
// 定义了一个双向链表的节点结构
typedef struct node {
    struct node *next, *prev;
    void *data;
} node_t;
// list_t 作为 node_t 的别名，用于表示链表本身
typedef node_t list_t;
```
定义的宏定义如下：
```c
// 遍历链表的每个元素的宏，正向遍历
#define list_each(this, node, item)                                   \
    for (node = (this)->next;                                         \
         item = node->data, node != (this);                           \
         node = node->next)
// 遍历链表的每个元素的宏，反向遍历
#define list_each_reverse(this, node, item)                           \
    for (node = (this)->prev;                                         \
         item = node->data, node != (this);                           \
         node = node->prev)
// 安全遍历链表的每个元素的宏，可以在遍历过程中修改链表结构
#define list_each_safe(this, curr, next, item)                        \
    for (curr = (this)->next, next = curr->next;                      \
         item = curr->data, curr != (this);                           \
         curr = next, next = curr->next)
```
定义的函数接口如下：
```c
// 创建一个新的节点
extern node_t *node_new(void *data);
// 删除一个节点
extern void node_delete(node_t *this);

// 检查节点是否已连接到链表
extern int node_is_attached(node_t *this);
// 检查节点是否未连接到链表
extern int node_is_detached(node_t *this);
// 从链表中断开节点
extern void node_unlink(node_t *this);
// 将一个节点插入到另一个节点之前
extern void node_prepend(node_t *this, node_t *that);
// 将一个节点插入到另一个节点之后
extern void node_append(node_t *this, node_t *that);

// 初始化链表
extern void list_init(list_t *this);
// 销毁链表
extern void list_destroy(list_t *this);
// 检查链表是否为空
extern int list_is_empty(list_t *this);

// 获取链表头部元素
extern void *list_get_head(list_t *this);
// 获取链表尾部元素
extern void *list_get_tail(list_t *this);

// 在链表头部插入元素
extern node_t *list_push_head(list_t *this, void *data);
// 从链表头部移除元素
extern void *list_pop_head(list_t *this);

// 在链表尾部插入元素
extern node_t *list_push_tail(list_t *this, void *data);
// 从链表尾部移除元素
extern void *list_pop_tail(list_t *this);

// 获取链表中元素的数量
extern int list_count(list_t *this);
// 根据索引获取链表中的元素
extern void *list_get(list_t *this, int index);
```
下面是一段使用list的示例代码和程序输出：
```c
// 定义一个学生信息链表
list_t student_list;

// 定义学生信息结构体
typedef struct {
    char *name; // 学生姓名
    char *sno;  // 学生学号
} student_t;

// 创建一个新的学生信息实例
student_t *student_new(char *name, char *sno)
{
    student_t *this = malloc(sizeof(student_t)); // 分配内存
    this->name = strdup(name); // 复制姓名字符串
    this->sno = strdup(sno);   // 复制学号字符串
    return this; // 返回学生信息指针
}

// 删除一个学生信息实例
void student_delete(student_t *this)
{
    free(this->name); // 释放姓名字符串占用的内存
    free(this->sno);  // 释放学号字符串占用的内存
    free(this);       // 释放学生信息结构体占用的内存
}

// 打印一个学生的信息
void student_dump(student_t *this)
{
    printf("student %s %s\n", this->name, this->sno); // 打印学生的姓名和学号
}

// 创建并初始化学生信息链表
void create_student_list()
{
    list_init(&student_list); // 初始化链表

    student_t *tom = student_new("tom", "001"); // 创建一个新的学生信息实例
    list_push_tail(&student_list, tom); // 将学生信息加入到链表的尾部

    student_t *mike = student_new("mike", "002"); // 创建另一个学生信息实例
    list_push_tail(&student_list, mike); // 同样将其加入到链表尾部

    student_t *jerry = student_new("jerry", "003"); // 创建第三个学生信息实例
    list_push_tail(&student_list, jerry); // 加入到链表尾部
}

// 遍历并打印链表中所有学生的信息
void dump_student_list()
{
    node_t *node;
    student_t *student;

    // 使用宏遍历链表中的每个元素
    list_each(&student_list, node, student)
        student_dump(student); // 打印当前遍历到的学生信息
}

// 销毁学生信息链表
void destroy_student_list()
{
    while (!list_is_empty(&student_list)) { // 判断链表是否为空
        student_t *student = list_pop_head(&student_list); // 从链表头部取出一个学生信息
        student_delete(student); // 删除该学生信息实例
    }
}

// 程序主入口
int main()
{
    create_student_list(); // 创建并初始化学生信息链表
    dump_student_list();   // 打印所有学生信息
    destroy_student_list(); // 销毁学生信息链表
    return 0;
}

```
输出如下：
```bash
student tom 001
student mike 002
student jerry 003
```

#### std.h

包含了常用的标准头文件，项目中的每个 C 文件都会引用该头文件

# dg版本控制的实现原理
## .dg文件夹结构
在项目的根目录下会生成一个 `.dg` 文件夹，该文件夹存储了版本库的所有数据，包括：
- objects 文件夹：存储所有的文件副本、版本tree和提交commit
- index 文件：存储索引区的文件列表
- HEAD 文件：存储当前版本的ID

.dg目录结构如下：
```
├── .dg
│   ├── HEAD
│   ├── index
│   └── objects
│       ├── 
│       

```
## 基本数据结构的定义

### 文件副本
每个版本都会有多个文件组成

每个文件都有一个文件副本，文件副本的名字即为ID，这些文件副本都存储在 `.dg\objects`文件夹中。每个文件副本都有一个唯一的 ID，ID 是使用哈希算法根据文件名字计算出来的，在本项目中ID取计算出来的哈希值的前四位。

如果两个文件的内容相同，则这两个文件的 ID 也相同。

文件副本的内容第一行为文件类型，如blob为二进制文本文件。后面剩余部分就是文件的内容。

### 版本tree
版本由多条记录构成，每条记录都有两个字段：文件的名称和文件副本的 ID。

版本tree本身也是一个文件，存储在 `.dg\objects` 文件夹中，版本文件的名字就是ID。同时也有一个唯一的 ID，ID有四位，第一位为2，后三位从000开始递增。

版本文件的内容中，第一行为tree，第二行是记录数目，后面的每一行都是一个文件的记录，记录的格式为`文件名 文件ID`。

### 提交commit
commit的数据结构由以下几部分组成：
- id: commit的ID，有四位，第一位为1，后三位从000开始递增。
- parent_id: 上一个commit的ID，若为0000说明是第一个commit
- tree_id: 本次commit的版本ID
- msg: 提交的日志信息

提交commit本身也是一个文件，存储在 `.dg\objects` 文件夹中，文件名就是id,每个提交都有一个唯一的 ID。

commit文件的内容第一行为parent_id，第二行为tree_id，第三行为msg。

### 索引index
索引就是当前版本tree文件，索引区的文件名为 `.dg\index`。
### HEAD
HEAD 文件存储当前提交commit的ID，HEAD 文件的内容就是当前提交commit的ID。

## 实现过程
### 初始化版本库
   
   使用命令`init`，会在项目根目录下生成 `.dg` 文件夹，同时生成索引文件和HEAD文件。
   
   初始化 HEAD 指向 0000，表示为空,初始化 INDEX 为空

### 添加文件到索引区
   
   使用命令`add`，将文件添加到索引区，如果是目录则将目录下的所有文件添加到索引区。
   
   添加文件到索引index时，计算文件的ID,同时会将文件的内容写入到 `.dg\objects` 文件夹中，将文件名和ID写入到索引文件中。

### 提交索引区的文件到版本库
    
    使用命令`commit -m msg`，该操作将分为两步。

    1. copy：第 1 步操作
    
        计算 index 的 ID 并将 index 的内容复制到 objects/ID 
    
    2. commit：第 2 步操作
   
        新增 1 条 commit 记录
        
        设置 parent_id 指向上一条提交记录
        
        设置 tree_id 指向对应的 tree
        
        设置 msg 为 msg
        
        计算本次 commit 的 ID，让 HEAD 指向它

### 恢复版本
        
    使用命令`checkout commit_id`，将指定版本的文件恢复到工作目录下。

    1. 读取 commit_id 对应的 commit 文件，获取 tree_id
    2. 读取 tree_id 对应的 tree 文件，获取文件列表
    3. 读取文件列表中的文件，将文件内容写入到工作目录中
    4. 更新 HEAD 文件
    5. 更新索引区
    6. 更新工作区
   

### 打印提交记录
        
    使用命令`log`，打印提交记录，包括commit的ID，parent_id，tree_id和msg。

    操作过程如下：
    1. 读取 HEAD 文件，获取当前 commit_id
    2. 读取 commit_id 对应的 commit 文件，获取 parent_id，tree_id 和 msg
    3. 打印 commit_id，parent_id，tree_id 和 msg
    4. 重复 2 和 3，直到 parent_id 为 0000
    5. 打印结束
    6. 退出
### 删除文件

    使用命令`rm`，将文件从索引区删除。

    删除文件时，删除索引区中的文件记录。
