-- liquibase formatted sql
-- 收费场馆预约 SaaS：31 张表；全新表结构初始化脚本，非升级补丁。
-- 目标：MySQL 8.0.16+ / PostgreSQL 14+；请使用与实际数据库匹配的文件。
-- 不创建数据库，不删除已有表，不插入真实用户或支付凭据；id 由应用 ID 生成器提供。
-- 同一脚本可由数据库客户端执行，或由随附 Liquibase master 按 dbms 选择执行。
-- 执行前选择专用目标数据库；重复执行会报表已存在，应由 Liquibase 管理重放。

-- changeset booking:20261014-bk_venue dbms:mysql
-- comment 创建场馆表
CREATE TABLE `bk_venue` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `code` VARCHAR(64) NOT NULL COMMENT '场馆编码',
    `name` VARCHAR(100) NOT NULL COMMENT '场馆名称',
    `timezone` VARCHAR(64) NOT NULL DEFAULT 'Asia/Shanghai' COMMENT '时区',
    `work_calendar_id` BIGINT NOT NULL COMMENT '工作日历ID',
    `address` VARCHAR(300) NOT NULL COMMENT '地址',
    `longitude` DECIMAL(11,7) NULL COMMENT '经度',
    `latitude` DECIMAL(10,7) NULL COMMENT '纬度',
    `contact_phone` VARCHAR(32) NULL COMMENT '联系电话',
    `cover_file_id` BIGINT NULL COMMENT '封面文件ID',
    `arrival_guide` TEXT NULL COMMENT '到场指引',
    `status` VARCHAR(20) NOT NULL DEFAULT 'DRAFT' COMMENT '状态（DRAFT：草稿；OPEN：营业中；SUSPENDED：暂停营业；ARCHIVED：已归档）',
    `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_venue_01` UNIQUE (`tenant_id`, `code`),
    CONSTRAINT `uk_bk_venue_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='场馆';
CREATE INDEX `idx_bk_venue_01` ON `bk_venue` (`tenant_id`, `work_calendar_id`);

-- changeset booking:20261014-bk_resource_type dbms:mysql
-- comment 创建资源类型表
CREATE TABLE `bk_resource_type` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `code` VARCHAR(64) NOT NULL COMMENT '资源类型编码',
    `name` VARCHAR(64) NOT NULL COMMENT '资源类型名称',
    `category` VARCHAR(20) NOT NULL DEFAULT 'SPACE' COMMENT '资源类别（SPACE：场地或空间；EQUIPMENT：设备或器材；STAFF：人员）',
    `attribute_schema` JSON NULL COMMENT '属性定义',
    `status` VARCHAR(20) NOT NULL DEFAULT 'ENABLED' COMMENT '状态（ENABLED：启用；DISABLED：停用）',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_resource_type_01` UNIQUE (`tenant_id`, `code`),
    CONSTRAINT `uk_bk_resource_type_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='资源类型';

-- changeset booking:20261014-bk_resource dbms:mysql
-- comment 创建具体资源表
CREATE TABLE `bk_resource` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `venue_id` BIGINT NOT NULL COMMENT '场馆ID',
    `resource_type_id` BIGINT NOT NULL COMMENT '资源类型ID',
    `code` VARCHAR(64) NOT NULL COMMENT '具体资源编码',
    `name` VARCHAR(100) NOT NULL COMMENT '具体资源名称',
    `inventory_mode` VARCHAR(20) NOT NULL DEFAULT 'EXCLUSIVE' COMMENT '库存模式（EXCLUSIVE：独占；SHARED：共享容量）',
    `capacity` INT NOT NULL DEFAULT 1 COMMENT '库存容量',
    `suggested_people` INT NULL COMMENT '建议人数',
    `slot_minutes` SMALLINT NOT NULL DEFAULT 30 COMMENT '库存片时长（分钟）',
    `attributes` JSON NULL COMMENT '资源属性',
    `cover_file_id` BIGINT NULL COMMENT '封面文件ID',
    `description` TEXT NULL COMMENT '说明',
    `status` VARCHAR(20) NOT NULL DEFAULT 'ENABLED' COMMENT '状态（ENABLED：启用；DISABLED：停用；ARCHIVED：已归档）',
    `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_resource_01` UNIQUE (`tenant_id`, `venue_id`, `code`),
    CONSTRAINT `uk_bk_resource_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='具体资源';
CREATE INDEX `idx_bk_resource_01` ON `bk_resource` (`tenant_id`, `resource_type_id`);
CREATE INDEX `idx_bk_resource_02` ON `bk_resource` (`tenant_id`, `venue_id`, `status`, `resource_type_id`);

-- changeset booking:20261014-bk_product dbms:mysql
-- comment 创建预约项目表
CREATE TABLE `bk_product` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `venue_id` BIGINT NOT NULL COMMENT '场馆ID',
    `code` VARCHAR(64) NOT NULL COMMENT '预约项目编码',
    `resource_type_id` BIGINT NOT NULL COMMENT '主资源类型ID',
    `name` VARCHAR(100) NOT NULL COMMENT '预约项目名称',
    `booking_policy_id` BIGINT NOT NULL COMMENT '预约政策ID',
    `price_plan_id` BIGINT NOT NULL COMMENT '价格方案ID',
    `pricing_mode` VARCHAR(20) NOT NULL DEFAULT 'PER_SLOT' COMMENT '计价方式（PER_SLOT：按库存片）',
    `description` TEXT NULL COMMENT '说明',
    `cover_file_id` BIGINT NULL COMMENT '封面文件ID',
    `status` VARCHAR(20) NOT NULL DEFAULT 'DRAFT' COMMENT '状态（DRAFT：草稿；PUBLISHED：已发布；OFFLINE：已下架；ARCHIVED：已归档）',
    `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_product_01` UNIQUE (`tenant_id`, `venue_id`, `code`),
    CONSTRAINT `uk_bk_product_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='预约项目';
CREATE INDEX `idx_bk_product_01` ON `bk_product` (`tenant_id`, `resource_type_id`);
CREATE INDEX `idx_bk_product_02` ON `bk_product` (`tenant_id`, `booking_policy_id`);
CREATE INDEX `idx_bk_product_03` ON `bk_product` (`tenant_id`, `price_plan_id`);

-- changeset booking:20261014-bk_product_resource dbms:mysql
-- comment 创建项目可售资源表
CREATE TABLE `bk_product_resource` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `product_id` BIGINT NOT NULL COMMENT '预约项目ID',
    `resource_id` BIGINT NOT NULL COMMENT '资源ID',
    `status` VARCHAR(20) NOT NULL DEFAULT 'ENABLED' COMMENT '状态（ENABLED：启用；DISABLED：停用）',
    `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_product_resource_01` UNIQUE (`tenant_id`, `product_id`, `resource_id`),
    CONSTRAINT `uk_bk_product_resource_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='项目可售资源';
CREATE INDEX `idx_bk_product_resource_01` ON `bk_product_resource` (`tenant_id`, `resource_id`);

-- changeset booking:20261014-bk_booking_policy dbms:mysql
-- comment 创建预约政策表
CREATE TABLE `bk_booking_policy` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `venue_id` BIGINT NOT NULL COMMENT '场馆ID',
    `code` VARCHAR(64) NOT NULL COMMENT '预约政策编码',
    `name` VARCHAR(100) NOT NULL COMMENT '预约政策名称',
    `revision_no` INT NOT NULL DEFAULT 1 COMMENT '业务版本号',
    `advance_days` SMALLINT NOT NULL DEFAULT 7 COMMENT '可提前预约天数',
    `release_local_time` TIME(0) NOT NULL DEFAULT '00:00:00' COMMENT '每日放号时间',
    `booking_cutoff_minutes` INT NOT NULL DEFAULT 0 COMMENT '预约截止提前量（分钟）',
    `min_duration_minutes` INT NOT NULL DEFAULT 60 COMMENT '最短预约时长（分钟）',
    `max_duration_minutes` INT NOT NULL DEFAULT 240 COMMENT '最长预约时长（分钟）',
    `payment_timeout_seconds` INT NOT NULL DEFAULT 600 COMMENT '付款超时时长（秒）',
    `cancel_allowed` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否允许自助取消',
    `cancel_cutoff_minutes` INT NOT NULL DEFAULT 120 COMMENT '取消截止提前量（分钟）',
    `refund_rules` JSON NOT NULL COMMENT '退款规则',
    `checkin_early_minutes` INT NOT NULL DEFAULT 15 COMMENT '允许提前签到分钟数',
    `checkin_late_minutes` INT NULL COMMENT '最晚签到延后分钟数',
    `require_checkout` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否要求结束登记',
    `no_show_policy` VARCHAR(30) NOT NULL DEFAULT 'KEEP_UNTIL_END' COMMENT '未到场处理方式（KEEP_UNTIL_END：保留至时段结束）',
    `status` VARCHAR(20) NOT NULL DEFAULT 'DRAFT' COMMENT '状态（DRAFT：草稿；ACTIVE：已生效；RETIRED：已退役）',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_booking_policy_01` UNIQUE (`tenant_id`, `venue_id`, `code`, `revision_no`),
    CONSTRAINT `uk_bk_booking_policy_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='预约政策';

-- changeset booking:20261014-bk_availability_rule dbms:mysql
-- comment 创建周期开放规则表
CREATE TABLE `bk_availability_rule` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `resource_id` BIGINT NOT NULL COMMENT '资源ID',
    `effective_from` DATE NOT NULL COMMENT '生效日期',
    `effective_to` DATE NULL COMMENT '失效日期',
    `day_type` VARCHAR(20) NOT NULL DEFAULT 'WEEKDAY' COMMENT '日期类型（WEEKDAY：按星期；WORKDAY：工作日；REST_DAY：休息日）',
    `weekday` SMALLINT NULL COMMENT '星期（1：周一；7：周日）',
    `start_local_time` TIME(0) NOT NULL COMMENT '当地开始时间',
    `end_local_time` TIME(0) NOT NULL COMMENT '当地结束时间',
    `end_day_offset` SMALLINT NOT NULL DEFAULT 0 COMMENT '结束日偏移（0：当天；1：次日）',
    `status` VARCHAR(20) NOT NULL DEFAULT 'ENABLED' COMMENT '状态（ENABLED：启用并参与匹配；DISABLED：停用且不参与匹配）',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_availability_rule_01` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='周期开放规则';
CREATE INDEX `idx_bk_availability_rule_01` ON `bk_availability_rule` (`tenant_id`, `resource_id`, `deleted`, `status`, `day_type`, `weekday`);

-- changeset booking:20261014-bk_calendar_exception dbms:mysql
-- comment 创建特殊日期与停用表
CREATE TABLE `bk_calendar_exception` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `resource_id` BIGINT NOT NULL COMMENT '资源ID',
    `exception_type` VARCHAR(20) NOT NULL COMMENT '例外类型',
    `start_at` DATETIME(3) NOT NULL COMMENT '开始时间',
    `end_at` DATETIME(3) NOT NULL COMMENT '结束时间',
    `reason` VARCHAR(300) NOT NULL COMMENT '原因',
    `status` VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' COMMENT '状态（ACTIVE：生效中；REVOKED：已撤销）',
    `approved_by` BIGINT NULL COMMENT '审批人ID',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_calendar_exception_01` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='特殊日期与停用';
CREATE INDEX `idx_bk_calendar_exception_01` ON `bk_calendar_exception` (`tenant_id`, `resource_id`, `status`, `start_at`, `end_at`);

-- changeset booking:20261014-bk_price_plan dbms:mysql
-- comment 创建价格方案表
CREATE TABLE `bk_price_plan` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `venue_id` BIGINT NOT NULL COMMENT '场馆ID',
    `code` VARCHAR(64) NOT NULL COMMENT '价格方案编码',
    `name` VARCHAR(100) NOT NULL COMMENT '价格方案名称',
    `revision_no` INT NOT NULL DEFAULT 1 COMMENT '业务版本号',
    `currency` CHAR(3) NOT NULL DEFAULT 'CNY' COMMENT '币种',
    `effective_from` DATE NOT NULL COMMENT '生效日期',
    `effective_to` DATE NULL COMMENT '失效日期',
    `status` VARCHAR(20) NOT NULL DEFAULT 'DRAFT' COMMENT '状态（DRAFT：草稿；ACTIVE：已生效；RETIRED：已退役）',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_price_plan_01` UNIQUE (`tenant_id`, `venue_id`, `code`, `revision_no`),
    CONSTRAINT `uk_bk_price_plan_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='价格方案';

-- changeset booking:20261014-bk_price_rule dbms:mysql
-- comment 创建价格规则表
CREATE TABLE `bk_price_rule` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `price_plan_id` BIGINT NOT NULL COMMENT '价格方案ID',
    `resource_type_id` BIGINT NULL COMMENT '资源类型ID',
    `resource_id` BIGINT NULL COMMENT '资源ID',
    `day_type` VARCHAR(20) NOT NULL DEFAULT 'WEEKDAY' COMMENT '日期类型（WEEKDAY：按星期；WORKDAY：工作日；REST_DAY：休息日；SPECIFIC_DATE：指定日期）',
    `weekday` SMALLINT NULL COMMENT '星期（1：周一；7：周日）',
    `specific_date` DATE NULL COMMENT '指定日期',
    `start_local_time` TIME(0) NOT NULL COMMENT '当地开始时间',
    `end_local_time` TIME(0) NOT NULL COMMENT '当地结束时间',
    `end_day_offset` SMALLINT NOT NULL DEFAULT 0 COMMENT '结束日偏移（0：当天；1：次日）',
    `amount_per_slot` BIGINT NOT NULL COMMENT '每库存片价格',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_price_rule_01` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='价格规则';
CREATE INDEX `idx_bk_price_rule_01` ON `bk_price_rule` (`tenant_id`, `resource_type_id`);
CREATE INDEX `idx_bk_price_rule_02` ON `bk_price_rule` (`tenant_id`, `resource_id`);
CREATE INDEX `idx_bk_price_rule_03` ON `bk_price_rule` (`tenant_id`, `price_plan_id`, `day_type`, `weekday`, `specific_date`);

-- changeset booking:20261014-bk_inventory_slot dbms:mysql
-- comment 创建库存片表
CREATE TABLE `bk_inventory_slot` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `venue_id` BIGINT NOT NULL COMMENT '场馆ID',
    `resource_id` BIGINT NOT NULL COMMENT '资源ID',
    `business_date` DATE NOT NULL COMMENT '营业日期',
    `start_at` DATETIME(3) NOT NULL COMMENT '开始时间',
    `end_at` DATETIME(3) NOT NULL COMMENT '结束时间',
    `capacity_total` INT NOT NULL DEFAULT 1 COMMENT '总容量',
    `held_quantity` INT NOT NULL DEFAULT 0 COMMENT '临时锁定数量',
    `booked_quantity` INT NOT NULL DEFAULT 0 COMMENT '已确认占用数量',
    `sale_status` VARCHAR(20) NOT NULL DEFAULT 'OPEN' COMMENT '可售状态（OPEN：开放销售；BLOCKED：临时停用；CLOSED：关闭销售）',
    `block_exception_id` BIGINT NULL COMMENT '停用记录ID',
    `calendar_revision` BIGINT NOT NULL COMMENT '排期批次号',
    `work_calendar_id` BIGINT NOT NULL COMMENT '工作日历ID',
    `day_type_snapshot` VARCHAR(20) NOT NULL COMMENT '日期类型快照（WORKDAY：工作日；REST_DAY：休息日）',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_inventory_slot_01` UNIQUE (`tenant_id`, `resource_id`, `start_at`),
    CONSTRAINT `uk_bk_inventory_slot_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='库存片';
CREATE INDEX `idx_bk_inventory_slot_01` ON `bk_inventory_slot` (`tenant_id`, `block_exception_id`);
CREATE INDEX `idx_bk_inventory_slot_02` ON `bk_inventory_slot` (`tenant_id`, `work_calendar_id`);
CREATE INDEX `idx_bk_inventory_slot_03` ON `bk_inventory_slot` (`tenant_id`, `venue_id`, `business_date`, `resource_id`);

-- changeset booking:20261014-bk_resource_reservation dbms:mysql
-- comment 创建资源预占表
CREATE TABLE `bk_resource_reservation` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `venue_id` BIGINT NOT NULL COMMENT '场馆ID',
    `order_item_id` BIGINT NOT NULL COMMENT '订单明细ID',
    `inventory_slot_id` BIGINT NOT NULL COMMENT '库存片ID',
    `resource_id` BIGINT NOT NULL COMMENT '资源ID',
    `allocation_role` VARCHAR(20) NOT NULL DEFAULT 'PRIMARY' COMMENT '资源分配角色（PRIMARY：主资源；STAFF：人员；ROOM：房间；EQUIPMENT：设备或器材）',
    `quantity` INT NOT NULL DEFAULT 1 COMMENT '数量',
    `status` VARCHAR(20) NOT NULL DEFAULT 'HELD' COMMENT '状态（HELD：临时锁定；CONFIRMED：已确认占用；RELEASED：已释放）',
    `expires_at` DATETIME(3) NULL COMMENT '预占到期时间',
    `confirmed_at` DATETIME(3) NULL COMMENT '确认时间',
    `released_at` DATETIME(3) NULL COMMENT '释放时间',
    `release_reason` VARCHAR(30) NULL COMMENT '释放原因',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_resource_reservation_01` UNIQUE (`tenant_id`, `order_item_id`, `inventory_slot_id`),
    CONSTRAINT `uk_bk_resource_reservation_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='资源预占';
CREATE INDEX `idx_bk_resource_reservation_01` ON `bk_resource_reservation` (`tenant_id`, `venue_id`);
CREATE INDEX `idx_bk_resource_reservation_02` ON `bk_resource_reservation` (`tenant_id`, `resource_id`);
CREATE INDEX `idx_bk_resource_reservation_03` ON `bk_resource_reservation` (`tenant_id`, `status`, `expires_at`);
CREATE INDEX `idx_bk_resource_reservation_04` ON `bk_resource_reservation` (`tenant_id`, `inventory_slot_id`, `status`);

-- changeset booking:20261014-bk_order dbms:mysql
-- comment 创建订单表
CREATE TABLE `bk_order` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `order_no` VARCHAR(64) NOT NULL COMMENT '订单号',
    `venue_id` BIGINT NOT NULL COMMENT '场馆ID',
    `customer_id` BIGINT NULL COMMENT '用户ID',
    `client_app_id` BIGINT NULL COMMENT '渠道应用ID',
    `contact_name` VARCHAR(64) NOT NULL COMMENT '联系人',
    `contact_phone` VARCHAR(64) NOT NULL COMMENT '联系电话',
    `contact_phone_hash` VARCHAR(128) NULL COMMENT '联系电话摘要',
    `source` VARCHAR(30) NOT NULL COMMENT '订单来源（MINIAPP：小程序；FRONT_DESK：前台；ADMIN：后台）',
    `source_operator_id` BIGINT NULL COMMENT '代订人ID',
    `client_request_id` VARCHAR(64) NOT NULL COMMENT '请求幂等标识',
    `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING_PAYMENT' COMMENT '状态（PENDING_PAYMENT：待付款；CONFIRMED：已确认；CANCELLED：已取消；CLOSED：未付款关闭；ENDED：使用权益已结束）',
    `currency` CHAR(3) NOT NULL DEFAULT 'CNY' COMMENT '币种',
    `list_amount` BIGINT NOT NULL COMMENT '原价金额',
    `discount_amount` BIGINT NOT NULL DEFAULT 0 COMMENT '优惠金额',
    `payable_amount` BIGINT NOT NULL COMMENT '应付金额',
    `paid_amount` BIGINT NOT NULL DEFAULT 0 COMMENT '已付金额',
    `refunded_amount` BIGINT NOT NULL DEFAULT 0 COMMENT '已退金额',
    `refund_pending_amount` BIGINT NOT NULL DEFAULT 0 COMMENT '退款预留金额',
    `payment_expires_at` DATETIME(3) NOT NULL COMMENT '付款截止时间',
    `confirmed_at` DATETIME(3) NULL COMMENT '确认时间',
    `cancelled_at` DATETIME(3) NULL COMMENT '取消时间',
    `closed_at` DATETIME(3) NULL COMMENT '关闭时间',
    `ended_at` DATETIME(3) NULL COMMENT '权益结束时间',
    `cancel_reason_code` VARCHAR(30) NULL COMMENT '取消原因编码',
    `cancel_reason` VARCHAR(300) NULL COMMENT '取消原因',
    `user_remark` VARCHAR(500) NULL COMMENT '用户备注',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_order_01` UNIQUE (`tenant_id`, `order_no`),
    CONSTRAINT `uk_bk_order_02` UNIQUE (`tenant_id`, `client_request_id`),
    CONSTRAINT `uk_bk_order_03` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='订单';
CREATE INDEX `idx_bk_order_01` ON `bk_order` (`tenant_id`, `client_app_id`);
CREATE INDEX `idx_bk_order_02` ON `bk_order` (`tenant_id`, `customer_id`, `create_time`, `id`);
CREATE INDEX `idx_bk_order_03` ON `bk_order` (`tenant_id`, `venue_id`, `status`, `create_time`);
CREATE INDEX `idx_bk_order_04` ON `bk_order` (`tenant_id`, `status`, `payment_expires_at`);
CREATE INDEX `idx_bk_order_05` ON `bk_order` (`tenant_id`, `contact_phone_hash`);

-- changeset booking:20261014-bk_order_item dbms:mysql
-- comment 创建订单明细表
CREATE TABLE `bk_order_item` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `order_id` BIGINT NOT NULL COMMENT '订单ID',
    `item_no` INT NOT NULL COMMENT '明细序号',
    `product_id` BIGINT NOT NULL COMMENT '预约项目ID',
    `primary_resource_id` BIGINT NOT NULL COMMENT '主资源ID',
    `product_name_snapshot` VARCHAR(100) NOT NULL COMMENT '项目名称快照',
    `resource_name_snapshot` VARCHAR(100) NOT NULL COMMENT '资源名称快照',
    `venue_name_snapshot` VARCHAR(100) NOT NULL COMMENT '场馆名称快照',
    `timezone_snapshot` VARCHAR(64) NOT NULL COMMENT '时区快照',
    `start_at` DATETIME(3) NOT NULL COMMENT '开始时间',
    `end_at` DATETIME(3) NOT NULL COMMENT '结束时间',
    `duration_minutes` INT NOT NULL COMMENT '预约时长（分钟）',
    `quantity` INT NOT NULL DEFAULT 1 COMMENT '数量',
    `expected_people` INT NULL COMMENT '预计人数',
    `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT '状态（PENDING：待付款确认；CONFIRMED：已确认；CANCELLED：已取消；CLOSED：未付款关闭；ENDED：使用权益已结束）',
    `list_amount` BIGINT NOT NULL COMMENT '原价金额',
    `discount_amount` BIGINT NOT NULL DEFAULT 0 COMMENT '优惠金额',
    `payable_amount` BIGINT NOT NULL COMMENT '应付金额',
    `refunded_amount` BIGINT NOT NULL DEFAULT 0 COMMENT '已退金额',
    `refund_pending_amount` BIGINT NOT NULL DEFAULT 0 COMMENT '退款预留金额',
    `booking_policy_id` BIGINT NOT NULL COMMENT '预约政策ID',
    `price_plan_id` BIGINT NOT NULL COMMENT '价格方案ID',
    `policy_snapshot` JSON NOT NULL COMMENT '预约政策快照',
    `extension_data` JSON NULL COMMENT '扩展信息',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_order_item_01` UNIQUE (`tenant_id`, `order_id`, `item_no`),
    CONSTRAINT `uk_bk_order_item_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='订单明细';
CREATE INDEX `idx_bk_order_item_01` ON `bk_order_item` (`tenant_id`, `product_id`);
CREATE INDEX `idx_bk_order_item_02` ON `bk_order_item` (`tenant_id`, `booking_policy_id`);
CREATE INDEX `idx_bk_order_item_03` ON `bk_order_item` (`tenant_id`, `price_plan_id`);
CREATE INDEX `idx_bk_order_item_04` ON `bk_order_item` (`tenant_id`, `primary_resource_id`, `start_at`);
CREATE INDEX `idx_bk_order_item_05` ON `bk_order_item` (`tenant_id`, `status`, `end_at`);

-- changeset booking:20261014-bk_order_item_segment dbms:mysql
-- comment 创建成交分段表
CREATE TABLE `bk_order_item_segment` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `order_item_id` BIGINT NOT NULL COMMENT '订单明细ID',
    `segment_no` INT NOT NULL COMMENT '分段序号',
    `inventory_slot_id` BIGINT NOT NULL COMMENT '库存片ID',
    `start_at` DATETIME(3) NOT NULL COMMENT '开始时间',
    `end_at` DATETIME(3) NOT NULL COMMENT '结束时间',
    `quantity` INT NOT NULL DEFAULT 1 COMMENT '数量',
    `price_rule_id` BIGINT NOT NULL COMMENT '价格规则ID',
    `work_calendar_id` BIGINT NOT NULL COMMENT '工作日历ID',
    `day_type_snapshot` VARCHAR(20) NOT NULL COMMENT '日期类型快照（WORKDAY：工作日；REST_DAY：休息日）',
    `unit_amount` BIGINT NOT NULL COMMENT '分段单价',
    `list_amount` BIGINT NOT NULL COMMENT '原价金额',
    `discount_amount` BIGINT NOT NULL DEFAULT 0 COMMENT '优惠金额',
    `payable_amount` BIGINT NOT NULL COMMENT '应付金额',
    `price_snapshot` JSON NOT NULL COMMENT '价格快照',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_order_item_segment_01` UNIQUE (`tenant_id`, `order_item_id`, `segment_no`),
    CONSTRAINT `uk_bk_order_item_segment_02` UNIQUE (`tenant_id`, `order_item_id`, `inventory_slot_id`),
    CONSTRAINT `uk_bk_order_item_segment_03` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='成交分段';
CREATE INDEX `idx_bk_order_item_segment_01` ON `bk_order_item_segment` (`tenant_id`, `inventory_slot_id`);
CREATE INDEX `idx_bk_order_item_segment_02` ON `bk_order_item_segment` (`tenant_id`, `price_rule_id`);
CREATE INDEX `idx_bk_order_item_segment_03` ON `bk_order_item_segment` (`tenant_id`, `work_calendar_id`);

-- changeset booking:20261014-bk_payment dbms:mysql
-- comment 创建支付尝试表
CREATE TABLE `bk_payment` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `payment_no` VARCHAR(64) NOT NULL COMMENT '支付单号',
    `order_id` BIGINT NOT NULL COMMENT '订单ID',
    `payment_account_id` BIGINT NULL COMMENT '支付账户ID',
    `payer_identity_id` BIGINT NULL COMMENT '付款人渠道身份ID',
    `channel` VARCHAR(30) NOT NULL COMMENT '渠道（WECHAT：微信；OFFLINE_CASH：线下现金；OFFLINE_OTHER：其他线下方式）',
    `amount` BIGINT NOT NULL COMMENT '支付金额',
    `currency` CHAR(3) NOT NULL COMMENT '币种',
    `status` VARCHAR(30) NOT NULL DEFAULT 'CREATED' COMMENT '状态（CREATED：已创建；PROCESSING：支付处理中；SUCCESS：支付成功；CLOSED：支付单已关闭；FAILED：支付失败）',
    `acceptance_status` VARCHAR(30) NOT NULL DEFAULT 'PENDING' COMMENT '付款接纳状态（PENDING：待业务确认；ACCEPTED：已接纳；EXCEPTION_REFUND：异常待退款）',
    `channel_transaction_no` VARCHAR(128) NULL COMMENT '渠道交易号',
    `channel_reference` VARCHAR(128) NULL COMMENT '渠道预支付标识',
    `requested_at` DATETIME(3) NOT NULL COMMENT '支付发起时间',
    `expires_at` DATETIME(3) NOT NULL COMMENT '付款截止时间',
    `paid_at` DATETIME(3) NULL COMMENT '支付成功时间',
    `confirmed_at` DATETIME(3) NULL COMMENT '确认时间',
    `offline_operator_id` BIGINT NULL COMMENT '线下收款人ID',
    `failure_code` VARCHAR(64) NULL COMMENT '失败编码',
    `failure_message` VARCHAR(300) NULL COMMENT '失败原因',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_payment_01` UNIQUE (`tenant_id`, `payment_no`),
    CONSTRAINT `uk_bk_payment_02` UNIQUE (`payment_account_id`, `channel_transaction_no`),
    CONSTRAINT `uk_bk_payment_03` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='支付尝试';
CREATE INDEX `idx_bk_payment_01` ON `bk_payment` (`tenant_id`, `payer_identity_id`);
CREATE INDEX `idx_bk_payment_02` ON `bk_payment` (`tenant_id`, `order_id`, `status`);
CREATE INDEX `idx_bk_payment_03` ON `bk_payment` (`tenant_id`, `status`, `requested_at`);

-- changeset booking:20261014-bk_refund dbms:mysql
-- comment 创建退款申请表
CREATE TABLE `bk_refund` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `refund_no` VARCHAR(64) NOT NULL COMMENT '退款单号',
    `order_id` BIGINT NOT NULL COMMENT '订单ID',
    `payment_id` BIGINT NOT NULL COMMENT '支付单ID',
    `refund_type` VARCHAR(30) NOT NULL COMMENT '退款类型（USER_CANCEL：用户取消；VENUE_CANCEL：场馆取消；AFTER_SALES：售后补偿；PAYMENT_EXCEPTION：异常付款）',
    `client_request_id` VARCHAR(64) NOT NULL COMMENT '请求幂等标识',
    `requested_amount` BIGINT NOT NULL COMMENT '申请退款金额',
    `succeeded_amount` BIGINT NOT NULL DEFAULT 0 COMMENT '成功退款金额',
    `currency` CHAR(3) NOT NULL COMMENT '币种',
    `status` VARCHAR(30) NOT NULL DEFAULT 'REQUESTED' COMMENT '状态（REQUESTED：已申请；PROCESSING：退款处理中；SUCCESS：退款成功；FAILED：退款失败；WITHDRAWN：申请已撤销）',
    `reserve_status` VARCHAR(20) NOT NULL DEFAULT 'RESERVED' COMMENT '退款额度状态（RESERVED：已预留；CONSUMED：已消耗；RELEASED：已释放）',
    `channel_refund_no` VARCHAR(128) NULL COMMENT '渠道退款单号',
    `reason_code` VARCHAR(30) NOT NULL COMMENT '原因编码',
    `reason` VARCHAR(300) NULL COMMENT '原因',
    `applicant_type` VARCHAR(20) NOT NULL COMMENT '申请人类型（CUSTOMER：用户；STAFF：人员；SYSTEM：系统）',
    `applicant_id` BIGINT NULL COMMENT '申请人ID',
    `calculation_snapshot` JSON NOT NULL COMMENT '退款计算快照',
    `requested_at` DATETIME(3) NOT NULL COMMENT '申请时间',
    `succeeded_at` DATETIME(3) NULL COMMENT '退款成功时间',
    `last_error` VARCHAR(300) NULL COMMENT '最近错误',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_refund_01` UNIQUE (`tenant_id`, `refund_no`),
    CONSTRAINT `uk_bk_refund_02` UNIQUE (`tenant_id`, `client_request_id`),
    CONSTRAINT `uk_bk_refund_03` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='退款申请';
CREATE INDEX `idx_bk_refund_01` ON `bk_refund` (`tenant_id`, `order_id`);
CREATE INDEX `idx_bk_refund_02` ON `bk_refund` (`tenant_id`, `payment_id`, `reserve_status`);
CREATE INDEX `idx_bk_refund_03` ON `bk_refund` (`tenant_id`, `status`, `requested_at`);

-- changeset booking:20261014-bk_refund_item dbms:mysql
-- comment 创建退款明细分摊表
CREATE TABLE `bk_refund_item` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `refund_id` BIGINT NOT NULL COMMENT '退款单ID',
    `order_item_id` BIGINT NOT NULL COMMENT '订单明细ID',
    `refund_amount` BIGINT NOT NULL COMMENT '退款分摊金额',
    `calculation_snapshot` JSON NULL COMMENT '退款计算快照',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_refund_item_01` UNIQUE (`tenant_id`, `refund_id`, `order_item_id`),
    CONSTRAINT `uk_bk_refund_item_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='退款明细分摊';
CREATE INDEX `idx_bk_refund_item_01` ON `bk_refund_item` (`tenant_id`, `order_item_id`);

-- changeset booking:20261014-bk_credential dbms:mysql
-- comment 创建使用凭证表
CREATE TABLE `bk_credential` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `credential_no` VARCHAR(64) NOT NULL COMMENT '凭证编号',
    `order_item_id` BIGINT NOT NULL COMMENT '订单明细ID',
    `token_digest` VARCHAR(128) NOT NULL COMMENT '凭证令牌摘要',
    `token_version` INT NOT NULL DEFAULT 1 COMMENT '凭证版本号',
    `valid_from` DATETIME(3) NOT NULL COMMENT '有效开始时间',
    `valid_to` DATETIME(3) NOT NULL COMMENT '有效结束时间',
    `status` VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' COMMENT '状态（ACTIVE：有效；REVOKED：已撤销；EXPIRED：已过期）',
    `issue_reason` VARCHAR(30) NOT NULL COMMENT '发放原因（PAYMENT_CONFIRMED：付款确认；REISSUED：重新发放）',
    `issued_at` DATETIME(3) NOT NULL COMMENT '发放时间',
    `revoked_at` DATETIME(3) NULL COMMENT '撤销时间',
    `revoke_reason` VARCHAR(100) NULL COMMENT '撤销原因',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_credential_01` UNIQUE (`tenant_id`, `credential_no`),
    CONSTRAINT `uk_bk_credential_02` UNIQUE (`token_digest`),
    CONSTRAINT `uk_bk_credential_03` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='使用凭证';
CREATE INDEX `idx_bk_credential_01` ON `bk_credential` (`tenant_id`, `order_item_id`);

-- changeset booking:20261014-bk_fulfillment dbms:mysql
-- comment 创建明细履约表
CREATE TABLE `bk_fulfillment` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `order_item_id` BIGINT NOT NULL COMMENT '订单明细ID',
    `venue_id` BIGINT NOT NULL COMMENT '场馆ID',
    `status` VARCHAR(30) NOT NULL DEFAULT 'NOT_ARRIVED' COMMENT '状态（NOT_ARRIVED：未到场；CHECKED_IN：已签到；IN_USE：使用中；COMPLETED：履约已完成；NO_SHOW：未到场爽约；ABORTED：履约已中止；CANCELLED：履约已取消）',
    `checkin_at` DATETIME(3) NULL COMMENT '签到时间',
    `checkin_operator_id` BIGINT NULL COMMENT '签到操作人ID',
    `actual_start_at` DATETIME(3) NULL COMMENT '实际开始时间',
    `actual_end_at` DATETIME(3) NULL COMMENT '实际结束时间',
    `completed_at` DATETIME(3) NULL COMMENT '履约完成时间',
    `completion_basis` VARCHAR(30) NULL COMMENT '履约完成依据（STAFF_CONFIRM：人工确认；DEVICE_EVENT：设备事件；CHECKED_IN_TIME_ELAPSED：已签到且权益到期）',
    `close_reason` VARCHAR(100) NULL COMMENT '结束原因',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_fulfillment_01` UNIQUE (`tenant_id`, `order_item_id`),
    CONSTRAINT `uk_bk_fulfillment_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='明细履约';
CREATE INDEX `idx_bk_fulfillment_01` ON `bk_fulfillment` (`tenant_id`, `venue_id`, `status`, `create_time`);

-- changeset booking:20261014-bk_verification_log dbms:mysql
-- comment 创建核验日志表
CREATE TABLE `bk_verification_log` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `fulfillment_id` BIGINT NOT NULL COMMENT '履约记录ID',
    `credential_id` BIGINT NULL COMMENT '凭证ID',
    `request_id` VARCHAR(64) NOT NULL COMMENT '请求标识',
    `action` VARCHAR(30) NOT NULL COMMENT '操作类型（CHECK_IN：签到；START_USE：开始使用；END_USE：结束使用；ABORT：中止使用）',
    `result` VARCHAR(20) NOT NULL COMMENT '操作结果（SUCCESS：成功；REJECTED：拒绝；ALREADY_DONE：已处理）',
    `reason_code` VARCHAR(50) NULL COMMENT '原因编码',
    `operator_user_id` BIGINT NULL COMMENT '操作人ID',
    `device_id` VARCHAR(64) NULL COMMENT '设备标识',
    `operation_mode` VARCHAR(20) NOT NULL COMMENT '操作方式（SCAN：扫码；MANUAL：人工；DEVICE：设备）',
    `venue_id` BIGINT NOT NULL COMMENT '场馆ID',
    `occurred_at` DATETIME(3) NOT NULL COMMENT '发生时间',
    `received_at` DATETIME(3) NOT NULL COMMENT '接收时间',
    `remark` VARCHAR(300) NULL COMMENT '备注',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_verification_log_01` UNIQUE (`tenant_id`, `request_id`),
    CONSTRAINT `uk_bk_verification_log_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='核验日志';
CREATE INDEX `idx_bk_verification_log_01` ON `bk_verification_log` (`tenant_id`, `credential_id`);
CREATE INDEX `idx_bk_verification_log_02` ON `bk_verification_log` (`tenant_id`, `venue_id`);
CREATE INDEX `idx_bk_verification_log_03` ON `bk_verification_log` (`tenant_id`, `fulfillment_id`, `occurred_at`);

-- changeset booking:20261014-bk_order_event dbms:mysql
-- comment 创建订单事件表
CREATE TABLE `bk_order_event` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `order_id` BIGINT NOT NULL COMMENT '订单ID',
    `order_item_id` BIGINT NULL COMMENT '订单明细ID',
    `event_type` VARCHAR(50) NOT NULL COMMENT '事件类型',
    `from_status` VARCHAR(30) NULL COMMENT '变更前状态',
    `to_status` VARCHAR(30) NULL COMMENT '变更后状态',
    `actor_type` VARCHAR(20) NOT NULL COMMENT '操作主体类型（CUSTOMER：用户；STAFF：人员；SYSTEM：系统；CHANNEL：渠道）',
    `actor_id` BIGINT NULL COMMENT '操作主体ID',
    `request_id` VARCHAR(64) NULL COMMENT '请求标识',
    `event_data` JSON NULL COMMENT '事件数据',
    `occurred_at` DATETIME(3) NOT NULL COMMENT '发生时间',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_order_event_01` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='订单事件';
CREATE INDEX `idx_bk_order_event_01` ON `bk_order_event` (`tenant_id`, `order_item_id`);
CREATE INDEX `idx_bk_order_event_02` ON `bk_order_event` (`tenant_id`, `order_id`, `occurred_at`);

-- changeset booking:20261014-bk_outbox_event dbms:mysql
-- comment 创建待投递事件表
CREATE TABLE `bk_outbox_event` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `event_id` VARCHAR(64) NOT NULL COMMENT '事件标识',
    `aggregate_type` VARCHAR(30) NOT NULL COMMENT '业务对象类型（ORDER：订单；REFUND：退款）',
    `aggregate_id` BIGINT NOT NULL COMMENT '业务对象ID',
    `event_type` VARCHAR(50) NOT NULL COMMENT '事件类型',
    `aggregate_sequence` BIGINT NOT NULL COMMENT '对象事件序号',
    `payload` JSON NOT NULL COMMENT '事件内容',
    `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT '状态（PENDING：待投递；PROCESSING：投递中；SENT：已投递；DEAD：待人工处理）',
    `attempts` INT NOT NULL DEFAULT 0 COMMENT '尝试次数',
    `next_attempt_at` DATETIME(3) NOT NULL COMMENT '下次执行时间',
    `locked_until` DATETIME(3) NULL COMMENT '处理租约到期时间',
    `sent_at` DATETIME(3) NULL COMMENT '投递时间',
    `last_error` VARCHAR(300) NULL COMMENT '最近错误',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_outbox_event_01` UNIQUE (`event_id`),
    CONSTRAINT `uk_bk_outbox_event_02` UNIQUE (`tenant_id`, `aggregate_type`, `aggregate_id`, `aggregate_sequence`),
    CONSTRAINT `uk_bk_outbox_event_03` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='待投递事件';
CREATE INDEX `idx_bk_outbox_event_01` ON `bk_outbox_event` (`status`, `next_attempt_at`);

-- changeset booking:20261014-bk_notification_task dbms:mysql
-- comment 创建通知任务表
CREATE TABLE `bk_notification_task` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `order_id` BIGINT NOT NULL COMMENT '订单ID',
    `event_id` VARCHAR(64) NOT NULL COMMENT '事件标识',
    `dedupe_key` VARCHAR(128) NOT NULL COMMENT '去重标识',
    `notification_type` VARCHAR(30) NOT NULL COMMENT '通知类型（BOOKING_CONFIRMED：预约确认；START_REMINDER：到场提醒；CANCELLED：已取消；REFUND_RESULT：退款结果）',
    `channel` VARCHAR(20) NOT NULL COMMENT '渠道（WECHAT_SUBSCRIBE：微信订阅消息；SMS：短信；IN_APP：站内消息）',
    `recipient_customer_id` BIGINT NULL COMMENT '接收用户ID',
    `client_app_id` BIGINT NULL COMMENT '渠道应用ID',
    `recipient_identity_id` BIGINT NULL COMMENT '接收人渠道身份ID',
    `recipient_address` VARCHAR(256) NULL COMMENT '接收地址',
    `template_code` VARCHAR(64) NOT NULL COMMENT '模板编码',
    `template_data` JSON NOT NULL COMMENT '模板参数',
    `scheduled_at` DATETIME(3) NOT NULL COMMENT '计划发送时间',
    `status` VARCHAR(20) NOT NULL DEFAULT 'PENDING' COMMENT '状态（PENDING：待发送；PROCESSING：发送中；SENT：已发送；FAILED：发送失败；CANCELLED：已取消发送）',
    `attempts` INT NOT NULL DEFAULT 0 COMMENT '尝试次数',
    `next_attempt_at` DATETIME(3) NULL COMMENT '下次执行时间',
    `locked_until` DATETIME(3) NULL COMMENT '处理租约到期时间',
    `sent_at` DATETIME(3) NULL COMMENT '发送时间',
    `last_error` VARCHAR(300) NULL COMMENT '最近错误',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_notification_task_01` UNIQUE (`tenant_id`, `dedupe_key`),
    CONSTRAINT `uk_bk_notification_task_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='通知任务';
CREATE INDEX `idx_bk_notification_task_01` ON `bk_notification_task` (`tenant_id`, `order_id`);
CREATE INDEX `idx_bk_notification_task_02` ON `bk_notification_task` (`tenant_id`, `recipient_customer_id`);
CREATE INDEX `idx_bk_notification_task_03` ON `bk_notification_task` (`tenant_id`, `client_app_id`);
CREATE INDEX `idx_bk_notification_task_04` ON `bk_notification_task` (`tenant_id`, `recipient_identity_id`);
CREATE INDEX `idx_bk_notification_task_05` ON `bk_notification_task` (`status`, `next_attempt_at`);

-- changeset booking:20261014-bk_customer dbms:mysql
-- comment 创建消费者账号表
CREATE TABLE `bk_customer` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `customer_no` VARCHAR(64) NOT NULL COMMENT '用户编号',
    `nickname` VARCHAR(100) NULL COMMENT '昵称',
    `avatar_file_id` BIGINT NULL COMMENT '头像文件ID',
    `mobile_country_code` VARCHAR(8) NULL COMMENT '电话国际区号',
    `mobile` VARCHAR(64) NULL COMMENT '手机号',
    `mobile_hash` VARCHAR(128) NULL COMMENT '手机号摘要',
    `mobile_verified_at` DATETIME(3) NULL COMMENT '手机号核验时间',
    `status` VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' COMMENT '状态（ACTIVE：正常；DISABLED：已禁用；CLOSED：已注销）',
    `register_source` VARCHAR(30) NOT NULL COMMENT '注册来源（WECHAT_MINIAPP：微信小程序；ADMIN_INVITE：后台邀请）',
    `registered_app_id` BIGINT NULL COMMENT '注册渠道应用ID',
    `registered_at` DATETIME(3) NOT NULL COMMENT '注册时间',
    `last_login_at` DATETIME(3) NULL COMMENT '最近登录时间',
    `closed_at` DATETIME(3) NULL COMMENT '注销时间',
    `close_reason` VARCHAR(300) NULL COMMENT '结束原因',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_customer_01` UNIQUE (`tenant_id`, `customer_no`),
    CONSTRAINT `uk_bk_customer_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='消费者账号';
CREATE INDEX `idx_bk_customer_01` ON `bk_customer` (`tenant_id`, `registered_app_id`);
CREATE INDEX `idx_bk_customer_02` ON `bk_customer` (`tenant_id`, `status`, `registered_at`);
CREATE INDEX `idx_bk_customer_03` ON `bk_customer` (`tenant_id`, `mobile_hash`);

-- changeset booking:20261014-bk_client_app dbms:mysql
-- comment 创建渠道应用绑定表
CREATE TABLE `bk_client_app` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `code` VARCHAR(64) NOT NULL COMMENT '渠道应用绑定编码',
    `name` VARCHAR(100) NOT NULL COMMENT '渠道应用绑定名称',
    `channel_type` VARCHAR(30) NOT NULL DEFAULT 'WECHAT_MINIAPP' COMMENT '应用类型（WECHAT_MINIAPP：微信小程序；H5：网页；APP：移动应用）',
    `provider` VARCHAR(30) NOT NULL DEFAULT 'WECHAT' COMMENT '身份提供方（WECHAT：微信）',
    `external_app_id` VARCHAR(128) NOT NULL COMMENT '外部应用ID',
    `open_platform_scope` VARCHAR(128) NULL COMMENT '开放平台作用域',
    `credential_config_ref` VARCHAR(128) NOT NULL COMMENT '渠道凭据配置引用',
    `login_enabled` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否允许登录',
    `notification_enabled` BOOLEAN NOT NULL DEFAULT TRUE COMMENT '是否启用通知',
    `status` VARCHAR(20) NOT NULL DEFAULT 'ENABLED' COMMENT '状态（ENABLED：启用；DISABLED：停用）',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_client_app_01` UNIQUE (`tenant_id`, `code`),
    CONSTRAINT `uk_bk_client_app_02` UNIQUE (`tenant_id`, `provider`, `external_app_id`),
    CONSTRAINT `uk_bk_client_app_03` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='渠道应用绑定';

-- changeset booking:20261014-bk_customer_identity dbms:mysql
-- comment 创建用户渠道身份表
CREATE TABLE `bk_customer_identity` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `customer_id` BIGINT NOT NULL COMMENT '用户ID',
    `client_app_id` BIGINT NULL COMMENT '渠道应用ID',
    `provider` VARCHAR(30) NOT NULL DEFAULT 'WECHAT' COMMENT '身份提供方（WECHAT：微信）',
    `identity_type` VARCHAR(30) NOT NULL COMMENT '身份类型（WECHAT_OPENID：微信OpenID；WECHAT_UNIONID：微信UnionID）',
    `issuer_scope` VARCHAR(128) NOT NULL COMMENT '身份作用域',
    `identifier_value` VARCHAR(512) NOT NULL COMMENT '渠道身份值',
    `identifier_hash` VARCHAR(128) NOT NULL COMMENT '渠道身份摘要',
    `status` VARCHAR(20) NOT NULL DEFAULT 'BOUND' COMMENT '状态（BOUND：已绑定；REVOKED：已撤销绑定）',
    `bound_at` DATETIME(3) NOT NULL COMMENT '绑定时间',
    `last_authenticated_at` DATETIME(3) NULL COMMENT '最近身份认证时间',
    `revoked_at` DATETIME(3) NULL COMMENT '撤销时间',
    `revoke_reason` VARCHAR(100) NULL COMMENT '解绑原因',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_customer_identity_01` UNIQUE (`tenant_id`, `provider`, `identity_type`, `issuer_scope`, `identifier_hash`),
    CONSTRAINT `uk_bk_customer_identity_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='用户渠道身份';
CREATE INDEX `idx_bk_customer_identity_01` ON `bk_customer_identity` (`tenant_id`, `client_app_id`);
CREATE INDEX `idx_bk_customer_identity_02` ON `bk_customer_identity` (`tenant_id`, `customer_id`, `status`);

-- changeset booking:20261014-bk_customer_contact dbms:mysql
-- comment 创建常用联系人表
CREATE TABLE `bk_customer_contact` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `customer_id` BIGINT NOT NULL COMMENT '用户ID',
    `contact_name` VARCHAR(64) NOT NULL COMMENT '联系人',
    `mobile_country_code` VARCHAR(8) NULL COMMENT '电话国际区号',
    `contact_phone` VARCHAR(64) NULL COMMENT '联系电话',
    `contact_phone_hash` VARCHAR(128) NULL COMMENT '联系电话摘要',
    `relationship` VARCHAR(30) NULL COMMENT '联系人关系（SELF：本人；FAMILY：家人；FRIEND：朋友；OTHER：其他）',
    `is_default` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否默认联系人',
    `sort_order` INT NOT NULL DEFAULT 0 COMMENT '排序',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_customer_contact_01` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='常用联系人';
CREATE INDEX `idx_bk_customer_contact_01` ON `bk_customer_contact` (`tenant_id`, `customer_id`, `deleted`, `sort_order`);

-- changeset booking:20261014-bk_order_participant dbms:mysql
-- comment 创建实际参与人表
CREATE TABLE `bk_order_participant` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `order_id` BIGINT NOT NULL COMMENT '订单ID',
    `order_item_id` BIGINT NULL COMMENT '订单明细ID',
    `participant_customer_id` BIGINT NULL COMMENT '参与用户ID',
    `source_contact_id` BIGINT NULL COMMENT '来源联系人ID',
    `participant_no` INT NOT NULL COMMENT '参与人序号',
    `name_snapshot` VARCHAR(64) NOT NULL COMMENT '姓名快照',
    `mobile_country_code` VARCHAR(8) NULL COMMENT '电话国际区号',
    `phone_snapshot` VARCHAR(64) NULL COMMENT '电话快照',
    `role` VARCHAR(30) NOT NULL DEFAULT 'ATTENDEE' COMMENT '参与人角色（ATTENDEE：参与人；LEADER：领队）',
    `status` VARCHAR(20) NOT NULL DEFAULT 'ACTIVE' COMMENT '状态（ACTIVE：有效参与；CANCELLED：已取消参与）',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_order_participant_01` UNIQUE (`tenant_id`, `order_id`, `participant_no`),
    CONSTRAINT `uk_bk_order_participant_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='实际参与人';
CREATE INDEX `idx_bk_order_participant_01` ON `bk_order_participant` (`tenant_id`, `order_item_id`);
CREATE INDEX `idx_bk_order_participant_02` ON `bk_order_participant` (`tenant_id`, `source_contact_id`);
CREATE INDEX `idx_bk_order_participant_03` ON `bk_order_participant` (`tenant_id`, `participant_customer_id`, `status`);

-- changeset booking:20261014-bk_work_calendar dbms:mysql
-- comment 创建工作日历表
CREATE TABLE `bk_work_calendar` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `code` VARCHAR(64) NOT NULL COMMENT '工作日历编码',
    `name` VARCHAR(100) NOT NULL COMMENT '工作日历名称',
    `revision_no` INT NOT NULL DEFAULT 1 COMMENT '业务版本号',
    `region_code` VARCHAR(32) NULL COMMENT '地区编码',
    `coverage_from` DATE NOT NULL COMMENT '覆盖开始日期',
    `coverage_to` DATE NOT NULL COMMENT '覆盖结束日期',
    `default_rest_weekdays` JSON NOT NULL DEFAULT (JSON_ARRAY(6, 7)) COMMENT '默认休息星期',
    `status` VARCHAR(20) NOT NULL DEFAULT 'DRAFT' COMMENT '状态（DRAFT：草稿；PUBLISHED：已发布；RETIRED：已退役）',
    `published_at` DATETIME(3) NULL COMMENT '发布时间',
    `remark` VARCHAR(500) NULL COMMENT '备注',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_work_calendar_01` UNIQUE (`tenant_id`, `code`, `revision_no`),
    CONSTRAINT `uk_bk_work_calendar_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='工作日历';

-- changeset booking:20261014-bk_work_calendar_day dbms:mysql
-- comment 创建日历日期明细表
CREATE TABLE `bk_work_calendar_day` (
    `id` BIGINT NOT NULL COMMENT '主键ID',
    `tenant_id` BIGINT NOT NULL COMMENT '租户ID',
    `work_calendar_id` BIGINT NOT NULL COMMENT '工作日历ID',
    `calendar_date` DATE NOT NULL COMMENT '日历日期',
    `day_type` VARCHAR(20) NOT NULL COMMENT '日期类型（WORKDAY：工作日；REST_DAY：休息日）',
    `is_holiday` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否节假日',
    `is_adjusted` BOOLEAN NOT NULL DEFAULT FALSE COMMENT '是否调休',
    `holiday_name` VARCHAR(100) NULL COMMENT '节假日名称',
    `source_type` VARCHAR(30) NOT NULL COMMENT '日期来源（WEEKLY_DEFAULT：星期模板；IMPORTED：导入；MANUAL：人工设置）',
    `source_reference` VARCHAR(300) NULL COMMENT '来源说明',
    `remark` VARCHAR(300) NULL COMMENT '备注',
    `create_user` BIGINT NULL COMMENT '创建人',
    `create_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '创建时间',
    `update_user` BIGINT NULL COMMENT '修改人',
    `update_time` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) COMMENT '修改时间',
    `deleted` BIGINT NOT NULL DEFAULT 0 COMMENT '是否已删除（0：否；id：是）',
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_bk_work_calendar_day_01` UNIQUE (`tenant_id`, `work_calendar_id`, `calendar_date`),
    CONSTRAINT `uk_bk_work_calendar_day_02` UNIQUE (`tenant_id`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4  COMMENT='日历日期明细';
CREATE INDEX `idx_bk_work_calendar_day_01` ON `bk_work_calendar_day` (`tenant_id`, `work_calendar_id`, `day_type`, `calendar_date`);

