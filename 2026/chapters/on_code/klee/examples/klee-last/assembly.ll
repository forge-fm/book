; ModuleID = 'examples/example.bc'
source_filename = "examples/example.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [2 x i8] c"0\00", align 1, !dbg !0
@.str.1 = private unnamed_addr constant [19 x i8] c"examples/example.c\00", align 1, !dbg !7
@__PRETTY_FUNCTION__.f = private unnamed_addr constant [17 x i8] c"void f(int, int)\00", align 1, !dbg !12
@.str.2 = private unnamed_addr constant [2 x i8] c"x\00", align 1, !dbg !18
@.str.3 = private unnamed_addr constant [2 x i8] c"y\00", align 1, !dbg !20

; Function Attrs: noinline nounwind uwtable
define dso_local void @f(i32 noundef %x, i32 noundef %y) #0 !dbg !32 {
entry:
  %x.addr = alloca i32, align 4
  %y.addr = alloca i32, align 4
  %tmp = alloca i32, align 4
  %z = alloca i32, align 4
  %w = alloca i32, align 4
  store i32 %x, ptr %x.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %x.addr, metadata !37, metadata !DIExpression()), !dbg !38
  store i32 %y, ptr %y.addr, align 4
  call void @llvm.dbg.declare(metadata ptr %y.addr, metadata !39, metadata !DIExpression()), !dbg !40
  %0 = load i32, ptr %x.addr, align 4, !dbg !41
  %1 = load i32, ptr %y.addr, align 4, !dbg !43
  %cmp = icmp sgt i32 %0, %1, !dbg !44
  br i1 %cmp, label %if.then, label %if.end6, !dbg !45

if.then:                                          ; preds = %entry
  call void @llvm.dbg.declare(metadata ptr %tmp, metadata !46, metadata !DIExpression()), !dbg !48
  %2 = load i32, ptr %x.addr, align 4, !dbg !49
  store i32 %2, ptr %tmp, align 4, !dbg !48
  %3 = load i32, ptr %y.addr, align 4, !dbg !50
  store i32 %3, ptr %x.addr, align 4, !dbg !51
  %4 = load i32, ptr %tmp, align 4, !dbg !52
  store i32 %4, ptr %y.addr, align 4, !dbg !53
  %5 = load i32, ptr %x.addr, align 4, !dbg !54
  %cmp1 = icmp sgt i32 %5, 0, !dbg !56
  %6 = load i32, ptr %y.addr, align 4
  %cmp2 = icmp sgt i32 %6, 0
  %or.cond = select i1 %cmp1, i1 %cmp2, i1 false, !dbg !57
  br i1 %or.cond, label %land.lhs.true3, label %if.end6, !dbg !57

land.lhs.true3:                                   ; preds = %if.then
  %7 = load i32, ptr %x.addr, align 4, !dbg !58
  %8 = load i32, ptr %y.addr, align 4, !dbg !59
  %sub = sub nsw i32 %7, %8, !dbg !60
  %cmp4 = icmp sgt i32 %sub, 0, !dbg !61
  br i1 %cmp4, label %if.then5, label %if.end6, !dbg !62

if.then5:                                         ; preds = %land.lhs.true3
  call void @__assert_fail(ptr noundef @.str, ptr noundef @.str.1, i32 noundef 11, ptr noundef @__PRETTY_FUNCTION__.f) #4, !dbg !63
  unreachable, !dbg !63

if.end6:                                          ; preds = %if.then, %land.lhs.true3, %entry
  call void @llvm.dbg.declare(metadata ptr %z, metadata !65, metadata !DIExpression()), !dbg !66
  %9 = load i32, ptr %x.addr, align 4, !dbg !67
  %shl = shl i32 %9, 7, !dbg !68
  store i32 %shl, ptr %z, align 4, !dbg !66
  call void @llvm.dbg.declare(metadata ptr %w, metadata !69, metadata !DIExpression()), !dbg !70
  %10 = load i32, ptr %x.addr, align 4, !dbg !71
  %and = and i32 %10, 255, !dbg !72
  store i32 %and, ptr %w, align 4, !dbg !70
  %11 = load i32, ptr %w, align 4, !dbg !73
  %tobool = icmp ne i32 %11, 0, !dbg !73
  br i1 %tobool, label %if.end8, label %if.then7, !dbg !75

if.then7:                                         ; preds = %if.end6
  call void @__assert_fail(ptr noundef @.str, ptr noundef @.str.1, i32 noundef 17, ptr noundef @__PRETTY_FUNCTION__.f) #4, !dbg !76
  unreachable, !dbg !76

if.end8:                                          ; preds = %if.end6
  ret void, !dbg !78
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare void @llvm.dbg.declare(metadata, metadata, metadata) #1

; Function Attrs: noreturn nounwind
declare void @__assert_fail(ptr noundef, ptr noundef, i32 noundef, ptr noundef) #2

; Function Attrs: noinline nounwind uwtable
define dso_local i32 @main() #0 !dbg !79 {
entry:
  %retval = alloca i32, align 4
  %x = alloca i32, align 4
  %y = alloca i32, align 4
  store i32 0, ptr %retval, align 4
  call void @llvm.dbg.declare(metadata ptr %x, metadata !82, metadata !DIExpression()), !dbg !83
  call void @llvm.dbg.declare(metadata ptr %y, metadata !84, metadata !DIExpression()), !dbg !85
  call void @klee_make_symbolic(ptr noundef %x, i64 noundef 4, ptr noundef @.str.2), !dbg !86
  call void @klee_make_symbolic(ptr noundef %y, i64 noundef 4, ptr noundef @.str.3), !dbg !87
  %0 = load i32, ptr %x, align 4, !dbg !88
  %1 = load i32, ptr %y, align 4, !dbg !89
  call void @f(i32 noundef %0, i32 noundef %1), !dbg !90
  ret i32 0, !dbg !91
}

declare void @klee_make_symbolic(ptr noundef, i64 noundef, ptr noundef) #3

attributes #0 = { noinline nounwind uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { noreturn nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { noreturn nounwind }

!llvm.dbg.cu = !{!22}
!llvm.module.flags = !{!24, !25, !26, !27, !28, !29, !30}
!llvm.ident = !{!31}

!0 = !DIGlobalVariableExpression(var: !1, expr: !DIExpression())
!1 = distinct !DIGlobalVariable(scope: null, file: !2, line: 11, type: !3, isLocal: true, isDefinition: true)
!2 = !DIFile(filename: "examples/example.c", directory: "/home/klee", checksumkind: CSK_MD5, checksum: "7846c708e2c7da74fc724d68b3ba742f")
!3 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 16, elements: !5)
!4 = !DIBasicType(name: "char", size: 8, encoding: DW_ATE_signed_char)
!5 = !{!6}
!6 = !DISubrange(count: 2)
!7 = !DIGlobalVariableExpression(var: !8, expr: !DIExpression())
!8 = distinct !DIGlobalVariable(scope: null, file: !2, line: 11, type: !9, isLocal: true, isDefinition: true)
!9 = !DICompositeType(tag: DW_TAG_array_type, baseType: !4, size: 152, elements: !10)
!10 = !{!11}
!11 = !DISubrange(count: 19)
!12 = !DIGlobalVariableExpression(var: !13, expr: !DIExpression())
!13 = distinct !DIGlobalVariable(scope: null, file: !2, line: 11, type: !14, isLocal: true, isDefinition: true)
!14 = !DICompositeType(tag: DW_TAG_array_type, baseType: !15, size: 136, elements: !16)
!15 = !DIDerivedType(tag: DW_TAG_const_type, baseType: !4)
!16 = !{!17}
!17 = !DISubrange(count: 17)
!18 = !DIGlobalVariableExpression(var: !19, expr: !DIExpression())
!19 = distinct !DIGlobalVariable(scope: null, file: !2, line: 23, type: !3, isLocal: true, isDefinition: true)
!20 = !DIGlobalVariableExpression(var: !21, expr: !DIExpression())
!21 = distinct !DIGlobalVariable(scope: null, file: !2, line: 24, type: !3, isLocal: true, isDefinition: true)
!22 = distinct !DICompileUnit(language: DW_LANG_C11, file: !2, producer: "clang version 16.0.6 (https://github.com/llvm/llvm-project.git 7cbf1a2591520c2491aa35339f227775f4d3adf6)", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, globals: !23, splitDebugInlining: false, nameTableKind: None)
!23 = !{!0, !7, !12, !18, !20}
!24 = !{i32 7, !"Dwarf Version", i32 5}
!25 = !{i32 2, !"Debug Info Version", i32 3}
!26 = !{i32 1, !"wchar_size", i32 4}
!27 = !{i32 8, !"PIC Level", i32 2}
!28 = !{i32 7, !"PIE Level", i32 2}
!29 = !{i32 7, !"uwtable", i32 2}
!30 = !{i32 7, !"frame-pointer", i32 2}
!31 = !{!"clang version 16.0.6 (https://github.com/llvm/llvm-project.git 7cbf1a2591520c2491aa35339f227775f4d3adf6)"}
!32 = distinct !DISubprogram(name: "f", scope: !2, file: !2, line: 5, type: !33, scopeLine: 5, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !22, retainedNodes: !36)
!33 = !DISubroutineType(types: !34)
!34 = !{null, !35, !35}
!35 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!36 = !{}
!37 = !DILocalVariable(name: "x", arg: 1, scope: !32, file: !2, line: 5, type: !35)
!38 = !DILocation(line: 5, column: 13, scope: !32)
!39 = !DILocalVariable(name: "y", arg: 2, scope: !32, file: !2, line: 5, type: !35)
!40 = !DILocation(line: 5, column: 20, scope: !32)
!41 = !DILocation(line: 6, column: 7, scope: !42)
!42 = distinct !DILexicalBlock(scope: !32, file: !2, line: 6, column: 7)
!43 = !DILocation(line: 6, column: 11, scope: !42)
!44 = !DILocation(line: 6, column: 9, scope: !42)
!45 = !DILocation(line: 6, column: 7, scope: !32)
!46 = !DILocalVariable(name: "tmp", scope: !47, file: !2, line: 7, type: !35)
!47 = distinct !DILexicalBlock(scope: !42, file: !2, line: 6, column: 14)
!48 = !DILocation(line: 7, column: 9, scope: !47)
!49 = !DILocation(line: 7, column: 15, scope: !47)
!50 = !DILocation(line: 8, column: 9, scope: !47)
!51 = !DILocation(line: 8, column: 7, scope: !47)
!52 = !DILocation(line: 9, column: 9, scope: !47)
!53 = !DILocation(line: 9, column: 7, scope: !47)
!54 = !DILocation(line: 10, column: 9, scope: !55)
!55 = distinct !DILexicalBlock(scope: !47, file: !2, line: 10, column: 9)
!56 = !DILocation(line: 10, column: 11, scope: !55)
!57 = !DILocation(line: 10, column: 15, scope: !55)
!58 = !DILocation(line: 10, column: 27, scope: !55)
!59 = !DILocation(line: 10, column: 31, scope: !55)
!60 = !DILocation(line: 10, column: 29, scope: !55)
!61 = !DILocation(line: 10, column: 33, scope: !55)
!62 = !DILocation(line: 10, column: 9, scope: !47)
!63 = !DILocation(line: 11, column: 8, scope: !64)
!64 = distinct !DILexicalBlock(scope: !55, file: !2, line: 10, column: 38)
!65 = !DILocalVariable(name: "z", scope: !32, file: !2, line: 14, type: !35)
!66 = !DILocation(line: 14, column: 7, scope: !32)
!67 = !DILocation(line: 14, column: 11, scope: !32)
!68 = !DILocation(line: 14, column: 13, scope: !32)
!69 = !DILocalVariable(name: "w", scope: !32, file: !2, line: 15, type: !35)
!70 = !DILocation(line: 15, column: 7, scope: !32)
!71 = !DILocation(line: 15, column: 11, scope: !32)
!72 = !DILocation(line: 15, column: 13, scope: !32)
!73 = !DILocation(line: 16, column: 8, scope: !74)
!74 = distinct !DILexicalBlock(scope: !32, file: !2, line: 16, column: 7)
!75 = !DILocation(line: 16, column: 7, scope: !32)
!76 = !DILocation(line: 17, column: 5, scope: !77)
!77 = distinct !DILexicalBlock(scope: !74, file: !2, line: 16, column: 11)
!78 = !DILocation(line: 19, column: 1, scope: !32)
!79 = distinct !DISubprogram(name: "main", scope: !2, file: !2, line: 21, type: !80, scopeLine: 21, spFlags: DISPFlagDefinition, unit: !22, retainedNodes: !36)
!80 = !DISubroutineType(types: !81)
!81 = !{!35}
!82 = !DILocalVariable(name: "x", scope: !79, file: !2, line: 22, type: !35)
!83 = !DILocation(line: 22, column: 7, scope: !79)
!84 = !DILocalVariable(name: "y", scope: !79, file: !2, line: 22, type: !35)
!85 = !DILocation(line: 22, column: 10, scope: !79)
!86 = !DILocation(line: 23, column: 3, scope: !79)
!87 = !DILocation(line: 24, column: 3, scope: !79)
!88 = !DILocation(line: 25, column: 5, scope: !79)
!89 = !DILocation(line: 25, column: 8, scope: !79)
!90 = !DILocation(line: 25, column: 3, scope: !79)
!91 = !DILocation(line: 26, column: 3, scope: !79)
