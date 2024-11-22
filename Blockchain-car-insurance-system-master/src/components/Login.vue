<template>
  <div class="login">
    <div>
      <Alert v-if="alert" v-bind:message="alert" v-on:removeAlert="alert=''"></Alert>
    </div>
    <div>
      <Alert v-if="alert1" v-bind:message="alert1" v-on:removeAlert="alert1=''"></Alert>
    </div>
    <div class="container">

      <form class="form-signin">
        <h2 class="form-signin-heading">Login</h2>

        <input type="email" class="form-control" placeholder="用户名" required autofocus v-model="user.userName">

        <input type="password" class="form-control" placeholder="密码" required v-model="user.password">

        <div>
          <label>您的身份:</label>
          <select v-model="user.type">
            <optgroup label="角色">
              <option v-for="type in types">{{type}}</option>
            </optgroup>
          </select>
        </div>

        <div class="checkbox">
          <label>
            <input type="checkbox" value="remember-me"> 记住我
          </label>
        </div>
        <button class="btn btn-lg btn-primary btn-block" type="submit" @click.prevent="userLogin">登录</button>
        <br>
        <router-link to='/registry'>没有账户？去注册</router-link>

      </form>

    </div> <!-- /container -->

  </div>
</template>

<script>
import Contracts from '../../libs/contracts';
import web3 from '../../libs/web3';
import Alert from './Alert';

export default {
  name: 'login',
  components: {
    Alert,
  },
  data () {
    return {
      user:{
        userName: '',
        password: '',
        type:'车主',
      },
      types: ['车主','保险公司','交警'],
      alert:'',
      alert1:'',
    }
  },
  methods:{
    async userLogin(e){

      //alert(this.user);
      //console.log(this.user);
      if (!(this.user.userName&&this.user.password&&this.user.type)) {
        alert("请把信息补充完整！");
      }
      else {
        const carOwnerList = Contracts['CarOwnerList'];
        const companyList = Contracts['CompanyList'];
        const policerList = Contracts['PolicerList'];
        const accounts = await web3.eth.getAccounts();
        const owner = accounts[0];

        let pwdRight = false;
        debugger
        try {
          if(this.user.type=='车主') {
            pwdRight = await carOwnerList.methods.verifyPwd(this.user.userName,this.user.password).call({from: owner});
            console.log(pwdRight);
            if(pwdRight) {
              let ownerAddr = await carOwnerList.methods.creatorOwnerMap(owner).call();
              this.$router.push("/owner/"+ownerAddr);
            }
          } else if(this.user.type=='保险公司') {
            pwdRight = await companyList.methods.verifyPwd(this.user.userName,this.user.password).call({from: owner});
            console.log(pwdRight);
            if(pwdRight) {
              let companyAddr = await companyList.methods.creatorCompanyMap(owner).call();
              this.$router.push("/company/"+companyAddr);
            }
          } else {
            pwdRight = await policerList.methods.verifyPwd(this.user.userName,this.user.password).call({from: owner});
            console.log(pwdRight);
            if(pwdRight) {
              let policerAddr = await policerList.methods.creatorPolicerMap(owner).call();
              this.$router.push("/police/"+policerAddr);
            }
          }
        } catch (err) {
          console.log(err.message);
          this.alert = err.message;
          pwdRight = true;
        }
        if(!pwdRight) {
          this.alert1 = "密码错误！";
        }
      }
      e.preventDefault();
    },
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
h1, h2 {
  font-weight: normal;
}
ul {
  list-style-type: none;
  padding: 0;
}
li {
  display: inline-block;
  margin: 0 10px;
}
a {
  padding-top: 20px;
  color: #42b983;
}

form{
  width: 500px;
  margin: 20px auto;
}

/* 样式重置（可选） */  
body {  
  font-family: 'Arial', sans-serif;  
  background-color: #f5f5f5;  
  margin: 0;  
  padding: 20px;  
}  

.login {  
  /* 这里可以为整个登录页面添加背景，如果需要的话 */  
  background-image: url('../img/banner11.jpg');  
  background-size: cover;  
  background-repeat: no-repeat;  
  background-position: center center;  

  /* 确保元素占据全屏空间 */  
  min-height: 100vh; /* 视口高度的100% */  
  display: flex; /* 使用flex布局来垂直和水平居中内容 */  
  justify-content: center; /* 水平居中 */  
  align-items: center; /* 垂直居中 */  
    
  /* 其他可能的样式 */  
  padding: 20px; /* 添加一些内边距以避免内容直接贴在边缘 */  
  box-sizing: border-box; /* 确保padding不会影响元素的总宽度和高度 */  
} 
  
/* 表单样式 */  
.form-signin {  
  max-width: 500px;  
  padding: 15px;  
  margin: 0 auto;  
  background-color: rgba(255, 255, 255, 0.3);
  border: 1px solid rgba(0,0,0,0.1);  
  border-radius: 5px;  
  box-shadow: 0 0 8px rgba(0, 0, 0, 0.1); 
}  
  
.form-signin .form-signin-heading {  
  font-family: 'Arial Black', Gadget, sans-serif; /* 使用粗体或装饰性字体 */  
  font-size: 2em; /* 字体大小 */  
  color: #333; /* 字体颜色 */  
  text-align: center; /* 文本居中对齐 */  
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5); /* 添加文字阴影 */  
  margin-bottom: 20px; /* 下边距，使标题与输入框之间有些间距 */  
  
  /* 模拟艺术字效果，可以通过修改以下属性来实现 */  
  letter-spacing: 2px; /* 字符间距 */  
  transform: skew(-5deg); /* 倾斜 */ 
}  

/* 设置输入框的半透明白色背景 */  
.form-signin .form-control {  
  background-color: rgba(255, 255, 255, 0.5); /* 半透明白色 */  
  /* border: 1px solid rgba(0, 0, 0, 0.2); 可选：半透明的边框颜色   */
  border-radius: 5px; /* 圆角 */  
  /* 可以添加其他输入框样式 */  
} 
  
.form-signin input[type="email"],  
.form-signin input[type="password"] {  
  position: relative;  
  font-size: 16px;  
  height: auto;  
  padding: 10px;  
  margin-bottom: 10px;  
}  
  
.form-signin select {  
  margin-bottom: 10px;  
  background-color: rgba(255, 255, 255, 0.3);
  border: 1px solid rgba(0,0,0,0.1);
}  
  
.form-signin .checkbox {  
  font-weight: normal;  
  
}  
  
.form-signin .checkbox label {  
  padding-left: 20px;  
}  
  
.form-signin .btn {  
  font-size: 16px;  
  font-weight: bold;  
}  
  
/* 链接样式 */  
.form-signin .router-link-exact-active {  
  color: #fff;  
  text-decoration: none;  
}  
  
.form-signin .router-link-exact-active:hover {  
  text-decoration: underline;  
}  
  
/* 自定义链接样式（如果你不使用Vue Router的类） */  
.form-signin a {  
  display: block;  
  text-align: center;  
  margin-top: 10px;  
  text-decoration: none;  
  color: #337ab7;  
}  
  
.form-signin a:hover {  
  text-decoration: underline;  
}  
  
/* 其他可能需要的样式 */  
.form-signin .form-group {  
  margin-bottom: 15px;  
}  
  
/* 表单项错误提示 */  
.form-signin .form-group.has-error .form-control {  
  border-color: #a94442;  
  box-shadow: inset 0 1px 1px rgba(0,0,0,.075);  
}  
  
.form-signin .form-group.has-error .help-block {  
  color: #a94442;  
}

</style>
