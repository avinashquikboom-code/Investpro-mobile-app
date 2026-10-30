import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
class InvestorRequestsView extends StatefulWidget {
  const InvestorRequestsView({super.key});
  @override
  State<InvestorRequestsView> createState()=>_InvestorRequestsViewState();
}
class _InvestorRequestsViewState extends State<InvestorRequestsView> {
  final title=TextEditingController(),message=TextEditingController();
  String kind='SUPPORT',error='',key=ApiService.newRequestKey();
  bool busy=false,more=true;
  int page=1;
  final records=<Map<String,dynamic>>[];
  @override
  void initState(){super.initState();load();}
  @override
  void dispose(){title.dispose();message.dispose();super.dispose();}
  Future<void> load({bool next=false}) async {
    try{
      final rows=await Get.find<ApiService>().requestHistory(page:next?page+1:1);
      final target=Get.arguments;
      Map<String,dynamic>? selected;
      if(!next && target is String) selected=await Get.find<ApiService>().requestDetail(target);
      if(mounted)setState((){if(!next){page=1;records.clear();}else{page++;}records.addAll(rows.map((r)=>Map<String,dynamic>.from(r as Map)));if(selected!=null&&!records.any((r)=>r['id']==selected!['id']))records.insert(0,selected);more=rows.length==25;error='';});
    }catch(_){if(mounted)setState(()=>error='Unable to load request history. Pull to refresh.');}
  }
  Future<void> submit()async{
    if(busy)return;
    if(title.text.trim().length<3||message.text.trim().length<10){setState(()=>error='Use a subject of at least 3 characters and a message of at least 10.');return;}
    setState(()=>busy=true);
    try{await Get.find<ApiService>().submitRequest(kind:kind,title:title.text.trim(),message:message.text.trim(),key:key);title.clear();message.clear();key=ApiService.newRequestKey();await load();}
    catch(_){if(mounted)setState(()=>error='Submission not confirmed. Check your connection and retry.');}
    finally{if(mounted)setState(()=>busy=false);}
  }
  @override
  Widget build(BuildContext context)=>Scaffold(appBar:const CustomAppBar(title:'Request History',showBackButton:true),body:RefreshIndicator(onRefresh:load,child:ListView(padding:const EdgeInsets.all(20),children:[
    if(error.isNotEmpty)Text(error,style:const TextStyle(color:AppColors.error)),
    DropdownButtonFormField<String>(initialValue:kind,items:const[DropdownMenuItem(value:'SUPPORT',child:Text('Support request')),DropdownMenuItem(value:'APPROVAL',child:Text('General approval request'))],onChanged:busy?null:(v)=>setState(()=>kind=v!)),
    TextField(controller:title,maxLength:120,decoration:const InputDecoration(labelText:'Subject')),
    TextField(controller:message,maxLength:4000,maxLines:3,decoration:const InputDecoration(labelText:'Message')),
    ElevatedButton.icon(onPressed:busy?null:submit,icon:const Icon(Remix.send_plane_line),label:Text(busy?'Submitting…':'Submit request')),
    const Padding(padding:EdgeInsets.symmetric(vertical:12),child:Text('Your requests',style:TextStyle(fontWeight:FontWeight.w600))),
    for(final item in records)Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(item['title'].toString(),style:const TextStyle(fontWeight:FontWeight.w600)),Text('${item['kind']} · ${item['status']}'),Text(item['createdAt'].toString()),Text(item['message'].toString()),if(item['response']!=null)Text('Admin response: ${item['response']}')]))),
    if(more)TextButton(onPressed:()=>load(next:true),child:const Text('Load more')),
  ])));
}
