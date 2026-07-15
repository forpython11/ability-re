<script lang="ts">
  // 根布局只负责加载全站样式，并把当前路由页面渲染到 children 位置。
  import '../app.css';
  let { children } = $props();
</script>

{@render children()}
