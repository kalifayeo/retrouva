<template>
  <div class="min-h-screen bg-ivoire-100 dark:bg-forest-900 transition-colors duration-200">
    <AdminSidebar />
    <main class="lg:pl-72">
      <AdminHeader />
      <slot />
    </main>
  </div>
</template>
