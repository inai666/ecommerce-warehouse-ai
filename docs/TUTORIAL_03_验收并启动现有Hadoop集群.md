# 教程 3：验收并启动现有 Hadoop 三节点集群

## 目标

复用已有 `master + slave1 + slave2` 集群，确认节点通信、配置、数据目录和进程角色正确，然后启动 HDFS/YARN 并完成最小读写测试。

本教程不重新安装 Hadoop，不格式化 NameNode，不改 XML。

## 第一阶段：启动前只读检查

在 master 以 hadoop 用户执行项目提供的命令块，确认：

- hosts 能解析三台主机；
- master 可以免密 SSH 到 slave1/slave2；
- workers 文件包含正确节点；
- NameNode/DataNode 数据目录存在；
- Hadoop 配置的属性名和值完整；
- 三台机器时间基本一致。

任何一项失败都先停止，不启动集群。

## 第二阶段：按原拓扑启动

只有第一阶段通过后：

1. master 执行 `start-dfs.sh`；
2. slave1 执行 `start-yarn.sh`；
3. 三台执行 `jps`；
4. master 执行 `hdfs dfsadmin -report`；
5. 访问 HDFS 与 YARN Web UI。

### 实际启动命令

先在 master 验证自身免密 SSH：

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 master 'hostname; date'
```

成功后在 master 启动 HDFS：

```bash
start-dfs.sh
jps
ssh slave1 jps
ssh slave2 jps
hdfs dfsadmin -report
```

确认 HDFS 正常后，在 slave1 终端启动 YARN：

```bash
start-yarn.sh
jps
ssh master jps
ssh slave2 jps
```

YARN 验收补充：

```bash
yarn node -list
```

预期 Active Nodes 为 3；若只显示 2，先检查 workers 与对应节点的 NodeManager 日志，不要重复执行启动命令。

不要将 HDFS 和 YARN 启动命令同时运行。先完成 HDFS 验收，再启动 YARN。

## 预期进程角色

实际角色以 XML 和 workers 输出为准，通常应看到：

| 节点 | 预期进程 |
|---|---|
| master | NameNode，可能还有 DataNode |
| slave1 | ResourceManager、NodeManager、DataNode |
| slave2 | SecondaryNameNode、NodeManager、DataNode |

如果进程角色不同，不要强行照表修改；先依据配置解释现状。

## 禁止操作

```bash
hdfs namenode -format
rm -rf /opt/module/hadoop/data
```

这两类操作可能破坏现有 HDFS 元数据。

## 实际验收结果（2026-08-12）

### HDFS

- master：NameNode、DataNode 正常；
- slave1：DataNode 正常；
- slave2：SecondaryNameNode、DataNode 正常；
- Live DataNodes：3；
- Under-replicated blocks、Corrupt replicas、Missing blocks 均为 0。

### YARN

- slave1：ResourceManager、NodeManager 正常；
- master、slave2：NodeManager 正常；
- `yarn node -list` 返回 3 个节点，状态均为 `RUNNING`。

### 最小闭环测试

已在 `/warehouse/ecommerce/tutorial03/input` 完成测试文本上传与回读，并通过 Hadoop examples 的 WordCount 作业验证 MapReduce：

- Map 进度：100%；
- Reduce 进度：100%；
- YARN 最终状态：`SUCCEEDED`；
- 输出目录：`/warehouse/ecommerce/tutorial03/output_wordcount_01`；
- 输出内容与预期词频一致。

结论：HDFS 读写、YARN 资源调度和 MapReduce 计算链路全部通过，可以进入 CSV 上传与 Hive ODS 建表阶段。

### 10K CSV 上传结果

- Windows 源文件大小：366,748 字节；
- Linux 本地行数：10,000；
- 文件没有表头，第一行是有效业务数据；
- HDFS 路径：`/warehouse/ecommerce/ods/raw/user_behavior_10k.csv`；
- HDFS 文件大小：366,748 字节，与 Windows 源文件一致。
