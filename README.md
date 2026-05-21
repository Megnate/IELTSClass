新增加的 claudeCode 大型项目最佳实践，是 Anthropic claude code 官方的一个文档生成的课件，是从此处粘贴而来：https://my.feishu.cn/wiki/XzbYwKs40iI5cEkHMHPcFMqtnaf 

你是一个前端架构师，也是一个资深的前端工程师。整个项目有70w行代码，分为很多个模块，从菜单来说：Home页面，Job模块，Wafer Queue模块，Recipe 模块，Sequence 模块，Offset 模块，User Permission模块，Wafer History模块，Chamber History模块，等等还有其他的模块，这里暂时记不清楚，后续还可以拓展这一部分的内容。

目标：将项目的 vue2 架构升级为 vue3 架构。我们的架构使用的是 vue-cli + vue-property-decorator + webpack+vuex + element-ui。这个地方后续需要升级为 vue3+pinia+vite+element-plus。

在每一次的动作之前，肯定是不同的开发拿着不同模块的代码使用这一份skill，然后去做代码的升级。你需要确保你升级之后的没有任何的代码错误，甚至来说没有功能也是没有错误的。所以一开始先分析相关的代码涉及多少，这个模块是否已经存在playwright相关的截图，便于修改之后去做验证，确保功能没有任何问题。

从这种注解的写法，到后面vue3的写法，可以不做写法上的升级，因为这一部分的代码，优先的是确保功能没有问题。

在这过程中，肯定会有总结的升级例子，甚至是你修改错误的经验教训，针对这些经验教训+升级典型例子，我需要你总结，然后以每种不同的类型当作一个md文档，避免同一个文档过长，在遇到错误或者开始之前，调用子agent来查找典型用例+经验教训。

每一次完成代码升级，最终需要一份HTML文档，详细的介绍你这一次的升级内容，并且你为什么这么做。在这过程中是否有总结经验教训，有参考什么典型例子，最终的验证情况，是否使用了 playwright 来进行验证，你的验证路径是怎么样的。

这是一个非常大的 skill，我也是需要这个 skill 来帮助我的团队来做这个代码的升级
