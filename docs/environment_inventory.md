# Hadoop 现有环境清单

更新时间：2026-08-12

## 已确认的 Windows/VMware 环境

- 宿主机：Windows，32 GB 内存
- CPU：AMD Ryzen 7 7735U
- 硬件虚拟化：已开启
- VMware Workstation：已安装
- 网络模式：三台虚拟机配置均为 NAT
- 来宾系统：CentOS 7 64-bit
- 单台配置：2 vCPU、2 GB 内存
- VMware Tools：未运行，无法从宿主机直接执行来宾命令或读取 IP

## 原集群逻辑拓扑

| Hadoop 角色 | VMware 目录/显示名 | 实际 hostname | IP | 状态 |
|---|---|---|---|---|
| master | VMware 显示名 master | master | 192.168.10.101 | 已启动，可登录控制台 |
| slave1 | VMware 显示名 slave1 | slave1 | 192.168.10.102 | 已启动，可登录控制台 |
| slave2 | VMware 显示名 slave2 | slave2 | 192.168.10.103 | 已启动，可登录控制台 |

说明：三台节点映射已由虚拟机内部 `hostname` 和 `hostname -I` 确认。各节点额外显示的 `192.168.122.1` 是来宾系统内部 libvirt 网桥，不用于 Hadoop 节点通信。旧的 `scala/node2/node3` 文件不是当前这套集群，不纳入项目环境。

## Word 记录中确认的信息

- HDFS 启动节点：master，命令 `start-dfs.sh`
- YARN 启动节点：slave1，命令 `start-yarn.sh`
- HDFS Web UI：`http://master:9870`
- YARN Web UI：`http://slave1:8088`
- 原集群使用普通 Hadoop 用户操作

安全说明：原 Word 文档包含明文凭据。凭据不写入本项目、不提交 Git，也不在教程中复述。建议环境恢复后修改弱密码并改用 SSH 密钥。

## 软件验收结果（master）

| 项目 | 结果 |
|---|---|
| 操作系统 | CentOS Linux 7.5.1804 (Core) |
| 内存 | 3.8 GB，可用约 2.4 GB（检查时） |
| 根分区 | 45 GB，总体使用 19%，剩余约 35 GB |
| Java | 1.8.0_212，`JAVA_HOME=/opt/module/jdk1.8.0_212` |
| Hadoop | 3.1.3，`HADOOP_HOME=/opt/module/hadoop` |
| Hive | 3.1.3，`HIVE_HOME=/opt/module/hive` |
| SSH | active |
| 当前 Java 进程 | 只有 Jps，HDFS/YARN 未启动 |

已观察到 Hive 启动时存在多个 SLF4J binding 警告。该警告不影响当前版本识别，先记录，后续若 Hive 查询出现日志冲突再处理。

## 已识别的 Hadoop 配置

- `fs.defaultFS`：`hdfs://master:8020`
- NameNode Web UI：`master:9870`
- HDFS 副本数：从截图初步识别为 2，启动前用属性名复核
- YARN ResourceManager：`slave1`
- YARN Web UI：`slave1:8088`
- NodeManager auxiliary service：`mapreduce_shuffle`

现有三节点集群是已搭建资产，不重新建设三节点。v5 项目只复用并验收该环境，项目复杂度仍控制在离线数仓本身。

## 启动前验收结果

- `/etc/hosts`：master/slave1/slave2 分别映射到 `192.168.10.101/102/103`
- workers：包含 `master`、`slave1`、`slave2`
- master 到 slave1/slave2：免密 SSH 成功
- 节点时间：相差约 1—5 秒，可用于当前离线实验
- Hadoop 数据根目录：`/opt/module/hadoop/data`
- NameNode 元数据目录：`/opt/module/hadoop/data/dfs/name/current` 存在
- DataNode 数据目录：`/opt/module/hadoop/data/dfs/data/current` 存在
- HDFS 默认副本数：2
- SecondaryNameNode：slave2
- ResourceManager：slave1
- NodeManager 容器内存：4096 MB；最小分配 2048 MB

结论：启动前只读检查通过，可以按原拓扑启动。禁止格式化 NameNode。

## HDFS 启动验收

- master：NameNode、DataNode 正常
- slave1：DataNode 正常
- slave2：SecondaryNameNode、DataNode 正常
- Live DataNodes：3
- Configured Capacity：约 132.50 GB
- DFS Remaining：约 105.06 GB
- DFS Used：约 12.40 MB
- Under-replicated blocks：0
- Corrupt replicas：0
- Missing blocks：0
- 三个 DataNode Decommission Status：Normal

HDFS 中已存在历史数据块，因此后续项目使用独立的 `/warehouse/ecommerce` 路径，禁止格式化或清理 Hadoop 数据目录。

## YARN 与 MapReduce 验收

- ResourceManager：slave1；
- NodeManager：master、slave1、slave2；
- `yarn node -list`：3 个节点，均为 `RUNNING`；
- HDFS 项目测试目录：`/warehouse/ecommerce/tutorial03`；
- 测试文件上传、列表查询和内容回读均成功；
- Hadoop WordCount 作业完成，最终状态为 `SUCCEEDED`。

结论：现有三节点集群的 HDFS、YARN、MapReduce 最小运行闭环已于 2026-08-12 验收通过。

## 待确认命令

在每台虚拟机登录后执行：

```bash
echo '=== HOST ==='
hostname
hostname -I
ip -4 addr show

echo '=== JAVA ==='
java -version

echo '=== HADOOP ==='
which hadoop
hadoop version

echo '=== HIVE ==='
which hive
hive --version

echo '=== PROCESS ==='
jps
```

先只探测，不执行 `start-dfs.sh`、`start-yarn.sh`、格式化 NameNode 或修改 XML。
