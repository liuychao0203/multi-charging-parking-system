# 智能（双充）停车平台

一个基于FPGA的智能停车平台系统，集成了步进电机控制和图像边缘检测功能。

## 📋 项目简介

本项目是一个智能停车平台控制系统，采用FPGA（现场可编程门阵列）实现，主要包含两个核心模块：

1. **步进电机控制系统** (`bujin_control`) - 实现停车平台的X/Y轴精确定位控制
2. **Sobel边缘检测系统** (`sobel`) - 实现基于OV5640摄像头的实时图像边缘检测和HDMI输出

## ✨ 主要功能
### 步进电机控制模块 (`bujin_control`)

- ✅ **双轴步进电机控制**：支持X轴和Y轴独立控制
- ✅ **多种控制方式**：
  - 手动按键控制
  - 蓝牙命令控制（UART通信）
  - 坐标自动控制
- ✅ **安全保护功能**：
  - 限位开关检测
  - 雨水传感器检测
  - 火焰传感器检测
  - 报警蜂鸣器
- ✅ **电机类型支持**：
  - 步进电机控制（X/Y轴）
  - 直流电机控制
  - 伺服电机控制
- ✅ **状态指示**：LED状态指示灯

### Sobel边缘检测模块 (`sobel`)

- ✅ **实时图像采集**：OV5640摄像头驱动
- ✅ **边缘检测算法**：Sobel算子实时边缘检测
- ✅ **视频处理流水线**：
  - RGB转YCbCr色彩空间转换
  - 3x3矩阵卷积处理
  - 行缓存（Line Buffer）实现
- ✅ **DDR3内存管理**：高效的视频帧缓存
- ✅ **HDMI输出**：实时显示处理后的视频流
- ✅ **I2C配置**：摄像头参数自动配置
## 📁 项目结构

```
43528智能（双充）停车平台/
├── bujin_control/              # 步进电机控制系统
│   ├── top_key_bujing.v       # 顶层模块
│   ├── stepper_motor_controller.v    # 步进电机控制器
│   ├── dc_motor_controller.v         # 直流电机控制器
│   ├── servo_controller.v            # 伺服电机控制器
│   ├── coordinate_controller.v       # 坐标控制器
│   ├── alarm_controller.v            # 报警控制器
│   ├── bluetooth_cmd_parser.v        # 蓝牙命令解析器
│   ├── uart_rx.v                     # UART接收器
│   ├── key_debounce1.v               # 按键消抖模块1
│   ├── key_debounce2.v               # 按键消抖模块2
│   ├── key_debounce3.v               # 按键消抖模块3
│   ├── finalsourse.xpr               # Vivado工程文件
│   └── finalsourse.runs/             # 综合和实现结果
│
└── sobel/                      # Sobel边缘检测系统
    ├── ov5640_hdmi_sobel.v     # 顶层模块
    ├── ov5640_dri.v            # OV5640摄像头驱动
    ├── i2c_dri.v               # I2C驱动
    ├── i2c_ov5640_rgb565_cfg.v # OV5640配置
    ├── cmos_capture_data.v     # CMOS数据采集
    ├── vip_sobel_edge_detector.v      # Sobel边缘检测器
    ├── vip_matrix_generate_3x3_8bit.v # 3x3矩阵生成器
    ├── line_shift_ram_8bit.v          # 行缓存模块
    ├── rgb2ycbcr.v                    # RGB转YCbCr
    ├── ddr3_top.v                     # DDR3顶层模块
    ├── ddr3_rw.v                      # DDR3读写控制
    ├── ddr3_fifo_ctrl.v               # DDR3 FIFO控制
    ├── hdmi_top.v                     # HDMI顶层模块
    ├── dvi_transmitter_top.v          # DVI发送器
    ├── dvi_encoder.v                  # DVI编码器
    ├── serializer_10_to_1.v           # 10:1串行化器
    ├── video_driver.v                 # 视频驱动
    ├── vip.v                          # 视频处理IP
    ├── asyn_rst_syn.v                 # 异步复位同步器
    └── hdmi_sobel(vivado工程）/       # Vivado工程目录
        └── hdmi_sobel/
            ├── prj/                   # 工程文件
            ├── rtl/                    # RTL源代码
            └── doc/                    # 文档
```

## 🛠️ 技术栈

- **硬件描述语言**：Verilog HDL
- **开发工具**：Xilinx Vivado (2019.2 / 2020.2)
- **目标平台**：Xilinx FPGA（具体型号请参考工程文件）
- **外设接口**：
  - UART（蓝牙通信）
  - I2C（摄像头配置）
  - HDMI/DVI（视频输出）
  - DDR3（视频帧缓存）

## 🚀 快速开始

### 环境要求

- Xilinx Vivado 2019.2 或更高版本
- 支持的FPGA开发板（请参考工程文件中的约束文件）

### 编译步骤

#### 步进电机控制模块

1. 打开Vivado
2. 打开工程：`bujin_control/finalsourse.xpr`
3. 运行综合（Synthesis）
4. 运行实现（Implementation）
5. 生成比特流（Generate Bitstream）

#### Sobel边缘检测模块

1. 打开Vivado
2. 打开工程：`sobel/hdmi_sobel(vivado工程）/hdmi_sobel/prj/ov5640_hdmi_sobel.xpr`
3. 运行综合（Synthesis）
4. 运行实现（Implementation）
5. 生成比特流（Generate Bitstream）

### 硬件连接

#### 步进电机控制模块接口

- **系统时钟**：50MHz
- **控制输入**：
  - `key1`：X轴正转按键
  - `key2`：X轴反转按键
  - `touchkey`：Y轴正转按键
  - `j14_sensor`：J14传感器输入
- **传感器输入**：
  - `rain_sensor`：雨水传感器
  - `flame_sensor`：火焰传感器
  - `x_limit_switch`：X轴限位开关
- **通信接口**：
  - `bt_rx`：蓝牙接收（UART）
- **电机输出**：
  - X轴：`EA1`, `DIR1`, `pwm_out1`
  - Y轴：`EA2`, `DIR2`, `pwm_out_y`
- **状态输出**：
  - `beep`：蜂鸣器
  - `led_status1/2/3`：LED状态指示

#### Sobel边缘检测模块接口

- **系统时钟**：系统主时钟
- **摄像头接口**：
  - `cam_pclk`：像素时钟
  - `cam_vsync`：场同步信号
  - `cam_href`：行同步信号
  - `cam_data[7:0]`：像素数据
  - `cam_scl`：I2C时钟
  - `cam_sda`：I2C数据
- **DDR3接口**：标准DDR3内存接口
- **HDMI输出**：标准HDMI接口

## 📊 性能指标

### 资源利用率

根据FPGA综合实现报告，本项目资源利用情况如下：

| 资源类型 | 已用数量 | 总可用数量 | 利用率 |
|---------|---------|-----------|--------|
| LUT (查找表) | 540 | 53,200 | 1.02% |
| FF (触发器) | 474 | 106,400 | 0.45% |
| IO (输入输出) | 26 | 125 | 20.80% |

### 总体优化效果

本项目在FPGA资源优化方面取得了显著成效。核心逻辑资源利用率极低：查找表（LUT）仅占用540个，利用率低至1.02%；触发器（FF）仅占用474个，利用率更是低至0.45%，这表明设计在实现完整功能的同时，对FPGA内部逻辑资源进行了高效管理和深度优化。核心逻辑资源的大量空闲（LUT和FF分别有98.98%和99.55%的可用空间）为未来功能扩展、算法升级和系统复杂度提升预留了充足的硬件资源。相比之下，输入输出（IO）资源利用率为20.80%（26/125），相对较高，这合理反映了系统与外部设备之间丰富的接口连接需求，包括步进电机控制、多种传感器接口、OV5640摄像头、HDMI视频输出等。整体而言，该设计在保证功能完整性和接口丰富性的同时，实现了核心逻辑资源的极致优化，展现了优秀的代码质量、高效的资源利用策略和良好的系统可扩展性，为后续添加更复杂的图像处理算法、多轴联动控制或人工智能功能奠定了坚实的硬件基础。

## 📖 模块说明

### 步进电机控制器 (`stepper_motor_controller.v`)

实现步进电机的脉冲生成、方向控制和使能管理。支持手动控制和坐标自动控制两种模式。

**主要参数**：
- `PULSE_FREQ`：脉冲频率（默认125kHz）

### 坐标控制器 (`coordinate_controller.v`)

实现基于坐标的自动定位控制，支持目标坐标设置和自动运行。

### 蓝牙命令解析器 (`bluetooth_cmd_parser.v`)

解析通过UART接收的蓝牙命令，支持多种控制指令。

### Sobel边缘检测器 (`vip_sobel_edge_detector.v`)

实现Sobel边缘检测算法，使用3x3卷积核进行实时边缘检测。

**主要参数**：
- `SOBEL_THRESHOLD`：边缘检测阈值（默认250）

### OV5640驱动 (`ov5640_dri.v`)

实现OV5640摄像头的驱动控制，包括数据采集和时序控制。

## 🔧 配置说明

### 步进电机参数配置

在 `stepper_motor_controller.v` 中可以修改以下参数：
- `PULSE_FREQ`：脉冲频率，根据电机规格调整

### Sobel检测参数配置

在 `vip_sobel_edge_detector.v` 中可以修改：
- `SOBEL_THRESHOLD`：边缘检测阈值，值越大检测越严格

## 📝 使用说明

### 步进电机控制

1. **手动控制模式**：
   - 按下 `key1` 控制X轴正转
   - 按下 `key2` 控制X轴反转
   - 按下 `touchkey` 控制Y轴正转

2. **蓝牙控制模式**：
   - 通过UART发送控制命令
   - 命令格式请参考 `bluetooth_cmd_parser.v`

3. **坐标控制模式**：
   - 通过坐标控制器设置目标位置
   - 系统自动运行到指定坐标

### 边缘检测使用

1. 连接OV5640摄像头
2. 连接HDMI显示器
3. 上电后系统自动初始化摄像头
4. 实时显示边缘检测结果

## ⚠️ 注意事项

1. **时钟约束**：请确保工程中包含正确的时钟约束文件（.xdc）
2. **引脚分配**：根据实际硬件修改引脚约束文件
3. **资源使用**：DDR3控制器会占用较多FPGA资源，请确保目标器件资源充足
4. **电源要求**：步进电机需要外部驱动电路，注意电源设计
5. **信号完整性**：HDMI和DDR3信号对PCB布线要求较高

## 📄 许可证

本项目为课程设计/毕业设计项目，仅供学习和研究使用。

## 👥 贡献

欢迎提交Issue和Pull Request！


---

**注意**：本项目为FPGA硬件项目，需要相应的硬件平台支持。使用前请确认硬件兼容性。

