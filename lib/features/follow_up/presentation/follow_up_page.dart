import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../students/domain/entities/student.dart';
import 'follow_up_providers.dart';

class FollowUpPage extends ConsumerStatefulWidget {
  const FollowUpPage({super.key,required this.student});
  final Student student;
  @override ConsumerState<FollowUpPage> createState()=>_FollowUpPageState();
}
class _FollowUpPageState extends ConsumerState<FollowUpPage>{
  String status='contacted',method='phone'; bool another=false;
  DateTime date=DateTime.now(),next=DateTime.now().add(const Duration(days:7));
  final reason=TextEditingController(),studentResponse=TextEditingController(),parentResponse=TextEditingController(),action=TextEditingController(),notes=TextEditingController();
  @override void dispose(){reason.dispose();studentResponse.dispose();parentResponse.dispose();action.dispose();notes.dispose();super.dispose();}
  @override Widget build(BuildContext context){
    final profile=ref.watch(currentServantProfileProvider);
    final servantId=profile.hasValue?profile.value!.id:null;
    final history=ref.watch(followUpRepositoryProvider).watchForStudent(widget.student.id);
    return Scaffold(appBar:AppBar(title:Text('متابعة — '+widget.student.name)),body:ListView(padding:const EdgeInsets.all(20),children:[
      Text('سجل المتابعة',style:Theme.of(context).textTheme.titleLarge),
      StreamBuilder(stream:history,builder:(context,snap){final rows=snap.data??const [];if(rows.isEmpty)return const Padding(padding:EdgeInsets.all(16),child:Text('لا توجد متابعات مسجلة بعد.'));return Column(children:rows.map((r)=>Card(child:ListTile(title:Text(r.followUpDate+' — '+(r.contactStatus=='contacted'?'تم التواصل':'لم يتم التواصل')),subtitle:Text(r.notes?.isNotEmpty==true?r.notes!:(r.actionRequired??''))))).toList());}),
      const Divider(height:32),
      DropdownButtonFormField<String>(initialValue:status,decoration:const InputDecoration(labelText:'الحالة'),items:const[DropdownMenuItem(value:'contacted',child:Text('تم التواصل')),DropdownMenuItem(value:'not_contacted',child:Text('لم يتم التواصل'))],onChanged:(v)=>setState(()=>status=v!)),
      DropdownButtonFormField<String>(initialValue:method,decoration:const InputDecoration(labelText:'طريقة التواصل'),items:const[DropdownMenuItem(value:'phone',child:Text('مكالمة')),DropdownMenuItem(value:'whatsapp',child:Text('WhatsApp')),DropdownMenuItem(value:'in_person',child:Text('مقابلة'))],onChanged:(v)=>setState(()=>method=v!)),
      ListTile(title:Text('تاريخ المتابعة: '+DateFormat('yyyy-MM-dd').format(date)),trailing:IconButton(icon:const Icon(Icons.calendar_month),onPressed:()async{final d=await showDatePicker(context:context,initialDate:date,firstDate:DateTime(2020),lastDate:DateTime(2100));if(d!=null)setState(()=>date=d);})),
      TextField(controller:reason,decoration:const InputDecoration(labelText:'سبب الغياب')),
      TextField(controller:studentResponse,decoration:const InputDecoration(labelText:'رد التلميذ')),
      TextField(controller:parentResponse,decoration:const InputDecoration(labelText:'رد ولي الأمر')),
      TextField(controller:action,decoration:const InputDecoration(labelText:'الإجراء المطلوب')),
      TextField(controller:notes,maxLines:3,decoration:const InputDecoration(labelText:'ملاحظات')),
      SwitchListTile(title:const Text('متابعة أخرى مطلوبة'),value:another,onChanged:(v)=>setState(()=>another=v)),
      if(another)ListTile(title:Text('المتابعة القادمة: '+DateFormat('yyyy-MM-dd').format(next)),trailing:IconButton(icon:const Icon(Icons.calendar_month),onPressed:()async{final d=await showDatePicker(context:context,initialDate:next,firstDate:DateTime(2020),lastDate:DateTime(2100));if(d!=null)setState(()=>next=d);})),
      FilledButton(onPressed:servantId==null?null:()async{await ref.read(followUpRepositoryProvider).create(studentId:widget.student.id,createdBy:servantId,followUpDate:DateFormat('yyyy-MM-dd').format(date),contactStatus:status,contactMethod:method,absenceReason:reason.text,studentResponse:studentResponse.text,parentResponse:parentResponse.text,actionRequired:action.text,notes:notes.text,anotherFollowUpNeeded:another,nextFollowUpDate:another?DateFormat('yyyy-MM-dd').format(next):null);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ المتابعة محليًا وسيتم مزامنتها.')));},child:const Text('حفظ المتابعة')),
    ]));
  }
}
