module CMockFunctionPrototype
  include Treetop::Runtime

  def root
    @root || :function_prototype
  end

  def _nt_function_prototype
    start_index = index
    if node_cache[:function_prototype].has_key?(index)
      cached = node_cache[:function_prototype][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0 = index
    r1 = _nt_function_prototype_function_pointer_return
    if r1
      r0 = r1
    else
      r2 = _nt_function_prototype_standard
      if r2
        r0 = r2
      else
        self.index = i0
        r0 = nil
      end
    end

    node_cache[:function_prototype][start_index] = r0

    return r0
  end

  module FunctionPrototypeStandard0
    def return_type
      elements[0]
    end

    def name
      elements[1]
    end

    def argument_list
      elements[2]
    end
  end

  def _nt_function_prototype_standard
    start_index = index
    if node_cache[:function_prototype_standard].has_key?(index)
      cached = node_cache[:function_prototype_standard][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_return_type
    s0 << r1
    if r1
      r2 = _nt_name
      s0 << r2
      if r2
        r3 = _nt_argument_list
        s0 << r3
      end
    end
    if s0.last
      r0 = instantiate_node(FunctionPrototypeStandardNode,input, i0...index, s0)
      r0.extend(FunctionPrototypeStandard0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:function_prototype_standard][start_index] = r0

    return r0
  end

  module FunctionPrototypeFunctionPointerReturn0
    def return_type
      elements[0]
    end

    def left_paren
      elements[1]
    end

    def asterisk
      elements[2]
    end

    def name
      elements[3]
    end

    def function_arglist
      elements[4]
    end

    def right_paren
      elements[5]
    end

    def function_return_arglist
      elements[6]
    end
  end

  def _nt_function_prototype_function_pointer_return
    start_index = index
    if node_cache[:function_prototype_function_pointer_return].has_key?(index)
      cached = node_cache[:function_prototype_function_pointer_return][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_return_type
    s0 << r1
    if r1
      r2 = _nt_left_paren
      s0 << r2
      if r2
        r3 = _nt_asterisk
        s0 << r3
        if r3
          r4 = _nt_name
          s0 << r4
          if r4
            r5 = _nt_argument_list
            s0 << r5
            if r5
              r6 = _nt_right_paren
              s0 << r6
              if r6
                r7 = _nt_argument_list
                s0 << r7
              end
            end
          end
        end
      end
    end
    if s0.last
      r0 = instantiate_node(FunctionPrototypeFunctionPointerReturnNode,input, i0...index, s0)
      r0.extend(FunctionPrototypeFunctionPointerReturn0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:function_prototype_function_pointer_return][start_index] = r0

    return r0
  end

  def _nt_return_type
    start_index = index
    if node_cache[:return_type].has_key?(index)
      cached = node_cache[:return_type][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0 = index
    r1 = _nt_void
    if r1
      r0 = r1
    else
      r2 = _nt_type
      if r2
        r0 = r2
      else
        self.index = i0
        r0 = nil
      end
    end

    node_cache[:return_type][start_index] = r0

    return r0
  end

  module ArgumentList0
    def argument
      elements[0]
    end

  end

  module ArgumentList1
    def left_paren
      elements[0]
    end

    def arguments
      elements[1]
    end

    def right_paren
      elements[2]
    end
  end

  def _nt_argument_list
    start_index = index
    if node_cache[:argument_list].has_key?(index)
      cached = node_cache[:argument_list][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_left_paren
    s0 << r1
    if r1
      s2, i2 = [], index
      loop do
        i3, s3 = index, []
        r4 = _nt_argument
        s3 << r4
        if r4
          r6 = _nt_comma
          if r6
            r5 = r6
          else
            r5 = instantiate_node(SyntaxNode,input, index...index)
          end
          s3 << r5
        end
        if s3.last
          r3 = instantiate_node(SyntaxNode,input, i3...index, s3)
          r3.extend(ArgumentList0)
        else
          self.index = i3
          r3 = nil
        end
        if r3
          s2 << r3
        else
          break
        end
      end
      r2 = instantiate_node(SyntaxNode,input, i2...index, s2)
      s0 << r2
      if r2
        r7 = _nt_right_paren
        s0 << r7
      end
    end
    if s0.last
      r0 = instantiate_node(ArgumentListNode,input, i0...index, s0)
      r0.extend(ArgumentList1)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:argument_list][start_index] = r0

    return r0
  end

  def _nt_argument
    start_index = index
    if node_cache[:argument].has_key?(index)
      cached = node_cache[:argument][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0 = index
    r1 = _nt_func_ptr_prototype
    if r1
      r0 = r1
    else
      r2 = _nt_void
      if r2
        r0 = r2
      else
        r3 = _nt_type_and_name
        if r3
          r0 = r3
        else
          r4 = _nt_variable_argument
          if r4
            r0 = r4
          else
            self.index = i0
            r0 = nil
          end
        end
      end
    end

    node_cache[:argument][start_index] = r0

    return r0
  end

  module VariableArgument0
    def space
      elements[1]
    end
  end

  def _nt_variable_argument
    start_index = index
    if node_cache[:variable_argument].has_key?(index)
      cached = node_cache[:variable_argument][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    if input.index('...', index) == index
      r1 = instantiate_node(SyntaxNode,input, index...(index + 3))
      @index += 3
    else
      terminal_parse_failure('...')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(VarArgNode,input, i0...index, s0)
      r0.extend(VariableArgument0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:variable_argument][start_index] = r0

    return r0
  end

  module FuncPtrPrototype0
    def return_type
      elements[0]
    end

    def name_and_args
      elements[1]
    end
  end

  def _nt_func_ptr_prototype
    start_index = index
    if node_cache[:func_ptr_prototype].has_key?(index)
      cached = node_cache[:func_ptr_prototype][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_return_type
    s0 << r1
    if r1
      r2 = _nt_parenthesized_func_ptr_name_with_arglist
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(FunctionPointerNode,input, i0...index, s0)
      r0.extend(FuncPtrPrototype0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:func_ptr_prototype][start_index] = r0

    return r0
  end

  module ParenthesizedFuncPtrNameWithArglist0
    def left_paren
      elements[0]
    end

    def name_and_args
      elements[1]
    end

    def right_paren
      elements[2]
    end
  end

  module ParenthesizedFuncPtrNameWithArglist1
    def left_paren
      elements[0]
    end

    def asterisk
      elements[1]
    end

    def const
      elements[2]
    end

    def name
      elements[3]
    end

    def right_paren
      elements[4]
    end

    def argument_list
      elements[5]
    end
  end

  def _nt_parenthesized_func_ptr_name_with_arglist
    start_index = index
    if node_cache[:parenthesized_func_ptr_name_with_arglist].has_key?(index)
      cached = node_cache[:parenthesized_func_ptr_name_with_arglist][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0 = index
    i1, s1 = index, []
    r2 = _nt_left_paren
    s1 << r2
    if r2
      r3 = _nt_parenthesized_func_ptr_name_with_arglist
      s1 << r3
      if r3
        r4 = _nt_right_paren
        s1 << r4
      end
    end
    if s1.last
      r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
      r1.extend(ParenthesizedFuncPtrNameWithArglist0)
    else
      self.index = i1
      r1 = nil
    end
    if r1
      r0 = r1
    else
      i5, s5 = index, []
      r6 = _nt_left_paren
      s5 << r6
      if r6
        r7 = _nt_asterisk
        s5 << r7
        if r7
          r9 = _nt_const
          if r9
            r8 = r9
          else
            r8 = instantiate_node(SyntaxNode,input, index...index)
          end
          s5 << r8
          if r8
            r11 = _nt_name
            if r11
              r10 = r11
            else
              r10 = instantiate_node(SyntaxNode,input, index...index)
            end
            s5 << r10
            if r10
              r12 = _nt_right_paren
              s5 << r12
              if r12
                r13 = _nt_argument_list
                s5 << r13
              end
            end
          end
        end
      end
      if s5.last
        r5 = instantiate_node(SyntaxNode,input, i5...index, s5)
        r5.extend(ParenthesizedFuncPtrNameWithArglist1)
      else
        self.index = i5
        r5 = nil
      end
      if r5
        r0 = r5
      else
        self.index = i0
        r0 = nil
      end
    end

    node_cache[:parenthesized_func_ptr_name_with_arglist][start_index] = r0

    return r0
  end

  module TypeAndName0
    def type
      elements[0]
    end

    def name
      elements[1]
    end

  end

  def _nt_type_and_name
    start_index = index
    if node_cache[:type_and_name].has_key?(index)
      cached = node_cache[:type_and_name][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_type
    s0 << r1
    if r1
      r3 = _nt_name_with_brackets
      if r3
        r2 = r3
      else
        r2 = instantiate_node(SyntaxNode,input, index...index)
      end
      s0 << r2
      if r2
        i4 = index
        i5 = index
        r6 = _nt_comma
        if r6
          r5 = r6
        else
          r7 = _nt_left_paren
          if r7
            r5 = r7
          else
            r8 = _nt_right_paren
            if r8
              r5 = r8
            else
              self.index = i5
              r5 = nil
            end
          end
        end
        if r5
          self.index = i4
          r4 = instantiate_node(SyntaxNode,input, index...index)
        else
          r4 = nil
        end
        s0 << r4
      end
    end
    if s0.last
      r0 = instantiate_node(TypeWithNameNode,input, i0...index, s0)
      r0.extend(TypeAndName0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:type_and_name][start_index] = r0

    return r0
  end

  module Type0
    def brackets
      elements[2]
    end
  end

  def _nt_type
    start_index = index
    if node_cache[:type].has_key?(index)
      cached = node_cache[:type][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    r2 = _nt_const
    if r2
      r1 = r2
    else
      r1 = instantiate_node(SyntaxNode,input, index...index)
    end
    s0 << r1
    if r1
      i3 = index
      r4 = _nt_type_struct
      if r4
        r3 = r4
      else
        r5 = _nt_type_union
        if r5
          r3 = r5
        else
          r6 = _nt_type_enum
          if r6
            r3 = r6
          else
            r7 = _nt_type_void_ptr
            if r7
              r3 = r7
            else
              r8 = _nt_type_primitive
              if r8
                r3 = r8
              else
                r9 = _nt_type_custom
                if r9
                  r3 = r9
                else
                  self.index = i3
                  r3 = nil
                end
              end
            end
          end
        end
      end
      s0 << r3
      if r3
        r11 = _nt_array_brackets
        if r11
          r10 = r11
        else
          r10 = instantiate_node(SyntaxNode,input, index...index)
        end
        s0 << r10
      end
    end
    if s0.last
      r0 = instantiate_node(TypeNode,input, i0...index, s0)
      r0.extend(Type0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:type][start_index] = r0

    return r0
  end

  module TypeStruct0
    def space
      elements[1]
    end

    def name
      elements[2]
    end

    def space
      elements[3]
    end

  end

  def _nt_type_struct
    start_index = index
    if node_cache[:type_struct].has_key?(index)
      cached = node_cache[:type_struct][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    if input.index('struct', index) == index
      r1 = instantiate_node(SyntaxNode,input, index...(index + 6))
      @index += 6
    else
      terminal_parse_failure('struct')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
      if r2
        r3 = _nt_name
        s0 << r3
        if r3
          r4 = _nt_space
          s0 << r4
          if r4
            r6 = _nt_type_const_and_ptr_suffix
            if r6
              r5 = r6
            else
              r5 = instantiate_node(SyntaxNode,input, index...index)
            end
            s0 << r5
          end
        end
      end
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(TypeStruct0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:type_struct][start_index] = r0

    return r0
  end

  module TypeUnion0
    def space
      elements[1]
    end

    def name
      elements[2]
    end

    def space
      elements[3]
    end

  end

  def _nt_type_union
    start_index = index
    if node_cache[:type_union].has_key?(index)
      cached = node_cache[:type_union][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    if input.index('union', index) == index
      r1 = instantiate_node(SyntaxNode,input, index...(index + 5))
      @index += 5
    else
      terminal_parse_failure('union')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
      if r2
        r3 = _nt_name
        s0 << r3
        if r3
          r4 = _nt_space
          s0 << r4
          if r4
            r6 = _nt_type_const_and_ptr_suffix
            if r6
              r5 = r6
            else
              r5 = instantiate_node(SyntaxNode,input, index...index)
            end
            s0 << r5
          end
        end
      end
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(TypeUnion0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:type_union][start_index] = r0

    return r0
  end

  module TypeEnum0
    def space
      elements[1]
    end

    def name
      elements[2]
    end

    def space
      elements[3]
    end

  end

  def _nt_type_enum
    start_index = index
    if node_cache[:type_enum].has_key?(index)
      cached = node_cache[:type_enum][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    if input.index('enum', index) == index
      r1 = instantiate_node(SyntaxNode,input, index...(index + 4))
      @index += 4
    else
      terminal_parse_failure('enum')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
      if r2
        r3 = _nt_name
        s0 << r3
        if r3
          r4 = _nt_space
          s0 << r4
          if r4
            r6 = _nt_type_const_and_ptr_suffix
            if r6
              r5 = r6
            else
              r5 = instantiate_node(SyntaxNode,input, index...index)
            end
            s0 << r5
          end
        end
      end
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(TypeEnum0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:type_enum][start_index] = r0

    return r0
  end

  module TypeVoidPtr0
    def space
      elements[1]
    end

    def type_const_and_ptr_suffix
      elements[2]
    end
  end

  def _nt_type_void_ptr
    start_index = index
    if node_cache[:type_void_ptr].has_key?(index)
      cached = node_cache[:type_void_ptr][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    if input.index('void', index) == index
      r1 = instantiate_node(SyntaxNode,input, index...(index + 4))
      @index += 4
    else
      terminal_parse_failure('void')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
      if r2
        r3 = _nt_type_const_and_ptr_suffix
        s0 << r3
      end
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(TypeVoidPtr0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:type_void_ptr][start_index] = r0

    return r0
  end

  module TypePrimitive0
    def space
      elements[1]
    end
  end

  module TypePrimitive1
    def space
      elements[1]
    end

  end

  module TypePrimitive2
    def space
      elements[2]
    end

  end

  def _nt_type_primitive
    start_index = index
    if node_cache[:type_primitive].has_key?(index)
      cached = node_cache[:type_primitive][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    i2, s2 = index, []
    i3 = index
    if input.index('unsigned', index) == index
      r4 = instantiate_node(SyntaxNode,input, index...(index + 8))
      @index += 8
    else
      terminal_parse_failure('unsigned')
      r4 = nil
    end
    if r4
      r3 = r4
    else
      if input.index('signed', index) == index
        r5 = instantiate_node(SyntaxNode,input, index...(index + 6))
        @index += 6
      else
        terminal_parse_failure('signed')
        r5 = nil
      end
      if r5
        r3 = r5
      else
        self.index = i3
        r3 = nil
      end
    end
    s2 << r3
    if r3
      r6 = _nt_space
      s2 << r6
    end
    if s2.last
      r2 = instantiate_node(SyntaxNode,input, i2...index, s2)
      r2.extend(TypePrimitive0)
    else
      self.index = i2
      r2 = nil
    end
    if r2
      r1 = r2
    else
      r1 = instantiate_node(SyntaxNode,input, index...index)
    end
    s0 << r1
    if r1
      i7 = index
      i8, s8 = index, []
      if input.index('long', index) == index
        r9 = instantiate_node(SyntaxNode,input, index...(index + 4))
        @index += 4
      else
        terminal_parse_failure('long')
        r9 = nil
      end
      s8 << r9
      if r9
        r10 = _nt_space
        s8 << r10
        if r10
          if input.index('int', index) == index
            r11 = instantiate_node(SyntaxNode,input, index...(index + 3))
            @index += 3
          else
            terminal_parse_failure('int')
            r11 = nil
          end
          s8 << r11
        end
      end
      if s8.last
        r8 = instantiate_node(SyntaxNode,input, i8...index, s8)
        r8.extend(TypePrimitive1)
      else
        self.index = i8
        r8 = nil
      end
      if r8
        r7 = r8
      else
        if input.index('long', index) == index
          r12 = instantiate_node(SyntaxNode,input, index...(index + 4))
          @index += 4
        else
          terminal_parse_failure('long')
          r12 = nil
        end
        if r12
          r7 = r12
        else
          if input.index('int', index) == index
            r13 = instantiate_node(SyntaxNode,input, index...(index + 3))
            @index += 3
          else
            terminal_parse_failure('int')
            r13 = nil
          end
          if r13
            r7 = r13
          else
            if input.index('short', index) == index
              r14 = instantiate_node(SyntaxNode,input, index...(index + 5))
              @index += 5
            else
              terminal_parse_failure('short')
              r14 = nil
            end
            if r14
              r7 = r14
            else
              if input.index('char', index) == index
                r15 = instantiate_node(SyntaxNode,input, index...(index + 4))
                @index += 4
              else
                terminal_parse_failure('char')
                r15 = nil
              end
              if r15
                r7 = r15
              else
                if input.index('float', index) == index
                  r16 = instantiate_node(SyntaxNode,input, index...(index + 5))
                  @index += 5
                else
                  terminal_parse_failure('float')
                  r16 = nil
                end
                if r16
                  r7 = r16
                else
                  if input.index('double', index) == index
                    r17 = instantiate_node(SyntaxNode,input, index...(index + 6))
                    @index += 6
                  else
                    terminal_parse_failure('double')
                    r17 = nil
                  end
                  if r17
                    r7 = r17
                  else
                    self.index = i7
                    r7 = nil
                  end
                end
              end
            end
          end
        end
      end
      s0 << r7
      if r7
        r18 = _nt_space
        s0 << r18
        if r18
          r20 = _nt_type_const_and_ptr_suffix
          if r20
            r19 = r20
          else
            r19 = instantiate_node(SyntaxNode,input, index...index)
          end
          s0 << r19
        end
      end
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(TypePrimitive2)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:type_primitive][start_index] = r0

    return r0
  end

  module TypeCustom0
    def name
      elements[0]
    end

    def space
      elements[1]
    end

  end

  def _nt_type_custom
    start_index = index
    if node_cache[:type_custom].has_key?(index)
      cached = node_cache[:type_custom][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_name
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
      if r2
        r4 = _nt_type_const_and_ptr_suffix
        if r4
          r3 = r4
        else
          r3 = instantiate_node(SyntaxNode,input, index...index)
        end
        s0 << r3
      end
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(TypeCustom0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:type_custom][start_index] = r0

    return r0
  end

  module TypeConstAndPtrSuffix0
  end

  module TypeConstAndPtrSuffix1
    def space
      elements[0]
    end

  end

  module TypeConstAndPtrSuffix2
    def space
      elements[0]
    end

  end

  module TypeConstAndPtrSuffix3
    def space
      elements[0]
    end

  end

  module TypeConstAndPtrSuffix4
  end

  module TypeConstAndPtrSuffix5
    def const
      elements[0]
    end

  end

  module TypeConstAndPtrSuffix6
  end

  def _nt_type_const_and_ptr_suffix
    start_index = index
    if node_cache[:type_const_and_ptr_suffix].has_key?(index)
      cached = node_cache[:type_const_and_ptr_suffix][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0 = index
    i1, s1 = index, []
    if input.index('const', index) == index
      r2 = instantiate_node(SyntaxNode,input, index...(index + 5))
      @index += 5
    else
      terminal_parse_failure('const')
      r2 = nil
    end
    s1 << r2
    if r2
      i3 = index
      i4, s4 = index, []
      s5, i5 = [], index
      loop do
        if input.index(' ', index) == index
          r6 = instantiate_node(SyntaxNode,input, index...(index + 1))
          @index += 1
        else
          terminal_parse_failure(' ')
          r6 = nil
        end
        if r6
          s5 << r6
        else
          break
        end
      end
      if s5.empty?
        self.index = i5
        r5 = nil
      else
        r5 = instantiate_node(SyntaxNode,input, i5...index, s5)
      end
      s4 << r5
      if r5
        i7 = index
        r8 = _nt_name
        if r8
          self.index = i7
          r7 = instantiate_node(SyntaxNode,input, index...index)
        else
          r7 = nil
        end
        s4 << r7
      end
      if s4.last
        r4 = instantiate_node(SyntaxNode,input, i4...index, s4)
        r4.extend(TypeConstAndPtrSuffix0)
      else
        self.index = i4
        r4 = nil
      end
      if r4
        r3 = r4
      else
        i9, s9 = index, []
        r10 = _nt_space
        s9 << r10
        if r10
          i11 = index
          r12 = _nt_comma
          if r12
            self.index = i11
            r11 = instantiate_node(SyntaxNode,input, index...index)
          else
            r11 = nil
          end
          s9 << r11
        end
        if s9.last
          r9 = instantiate_node(SyntaxNode,input, i9...index, s9)
          r9.extend(TypeConstAndPtrSuffix1)
        else
          self.index = i9
          r9 = nil
        end
        if r9
          r3 = r9
        else
          i13, s13 = index, []
          r14 = _nt_space
          s13 << r14
          if r14
            i15 = index
            r16 = _nt_right_paren
            if r16
              self.index = i15
              r15 = instantiate_node(SyntaxNode,input, index...index)
            else
              r15 = nil
            end
            s13 << r15
          end
          if s13.last
            r13 = instantiate_node(SyntaxNode,input, i13...index, s13)
            r13.extend(TypeConstAndPtrSuffix2)
          else
            self.index = i13
            r13 = nil
          end
          if r13
            r3 = r13
          else
            i17, s17 = index, []
            r18 = _nt_space
            s17 << r18
            if r18
              i19 = index
              r20 = _nt_left_paren
              if r20
                self.index = i19
                r19 = instantiate_node(SyntaxNode,input, index...index)
              else
                r19 = nil
              end
              s17 << r19
            end
            if s17.last
              r17 = instantiate_node(SyntaxNode,input, i17...index, s17)
              r17.extend(TypeConstAndPtrSuffix3)
            else
              self.index = i17
              r17 = nil
            end
            if r17
              r3 = r17
            else
              self.index = i3
              r3 = nil
            end
          end
        end
      end
      s1 << r3
    end
    if s1.last
      r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
      r1.extend(TypeConstAndPtrSuffix4)
    else
      self.index = i1
      r1 = nil
    end
    if r1
      r0 = r1
    else
      i21, s21 = index, []
      r22 = _nt_const
      s21 << r22
      if r22
        s23, i23 = [], index
        loop do
          r24 = _nt_asterisk
          if r24
            s23 << r24
          else
            break
          end
        end
        if s23.empty?
          self.index = i23
          r23 = nil
        else
          r23 = instantiate_node(SyntaxNode,input, i23...index, s23)
        end
        s21 << r23
      end
      if s21.last
        r21 = instantiate_node(SyntaxNode,input, i21...index, s21)
        r21.extend(TypeConstAndPtrSuffix5)
      else
        self.index = i21
        r21 = nil
      end
      if r21
        r0 = r21
      else
        i25, s25 = index, []
        s26, i26 = [], index
        loop do
          r27 = _nt_asterisk
          if r27
            s26 << r27
          else
            break
          end
        end
        if s26.empty?
          self.index = i26
          r26 = nil
        else
          r26 = instantiate_node(SyntaxNode,input, i26...index, s26)
        end
        s25 << r26
        if r26
          r29 = _nt_const
          if r29
            r28 = r29
          else
            r28 = instantiate_node(SyntaxNode,input, index...index)
          end
          s25 << r28
        end
        if s25.last
          r25 = instantiate_node(SyntaxNode,input, i25...index, s25)
          r25.extend(TypeConstAndPtrSuffix6)
        else
          self.index = i25
          r25 = nil
        end
        if r25
          r0 = r25
        else
          self.index = i0
          r0 = nil
        end
      end
    end

    node_cache[:type_const_and_ptr_suffix][start_index] = r0

    return r0
  end

  module Name0
    def space
      elements[1]
    end
  end

  def _nt_name
    start_index = index
    if node_cache[:name].has_key?(index)
      cached = node_cache[:name][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    s1, i1 = [], index
    loop do
      if input.index(Regexp.new('[a-zA-Z0-9_]'), index) == index
        r2 = instantiate_node(SyntaxNode,input, index...(index + 1))
        @index += 1
      else
        r2 = nil
      end
      if r2
        s1 << r2
      else
        break
      end
    end
    if s1.empty?
      self.index = i1
      r1 = nil
    else
      r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
    end
    s0 << r1
    if r1
      r3 = _nt_space
      s0 << r3
    end
    if s0.last
      r0 = instantiate_node(NameNode,input, i0...index, s0)
      r0.extend(Name0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:name][start_index] = r0

    return r0
  end

  module NameWithBrackets0
    def name
      elements[0]
    end

    def brackets
      elements[1]
    end
  end

  def _nt_name_with_brackets
    start_index = index
    if node_cache[:name_with_brackets].has_key?(index)
      cached = node_cache[:name_with_brackets][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_name
    s0 << r1
    if r1
      r3 = _nt_array_brackets
      if r3
        r2 = r3
      else
        r2 = instantiate_node(SyntaxNode,input, index...index)
      end
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(NameWithBracketsNode,input, i0...index, s0)
      r0.extend(NameWithBrackets0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:name_with_brackets][start_index] = r0

    return r0
  end

  module Void0
    def space
      elements[1]
    end

  end

  def _nt_void
    start_index = index
    if node_cache[:void].has_key?(index)
      cached = node_cache[:void][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    if input.index('void', index) == index
      r1 = instantiate_node(SyntaxNode,input, index...(index + 4))
      @index += 4
    else
      terminal_parse_failure('void')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
      if r2
        i3 = index
        r4 = _nt_asterisk
        if r4
          r3 = nil
        else
          self.index = i3
          r3 = instantiate_node(SyntaxNode,input, index...index)
        end
        s0 << r3
      end
    end
    if s0.last
      r0 = instantiate_node(VoidNode,input, i0...index, s0)
      r0.extend(Void0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:void][start_index] = r0

    return r0
  end

  module ArrayBrackets0
    def left_bracket
      elements[0]
    end

    def number
      elements[1]
    end

    def right_bracket
      elements[2]
    end
  end

  module ArrayBrackets1
    def left_bracket
      elements[0]
    end

    def right_bracket
      elements[1]
    end

  end

  def _nt_array_brackets
    start_index = index
    if node_cache[:array_brackets].has_key?(index)
      cached = node_cache[:array_brackets][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    r1 = _nt_left_bracket
    s0 << r1
    if r1
      r2 = _nt_right_bracket
      s0 << r2
      if r2
        s3, i3 = [], index
        loop do
          i4, s4 = index, []
          r5 = _nt_left_bracket
          s4 << r5
          if r5
            r6 = _nt_number
            s4 << r6
            if r6
              r7 = _nt_right_bracket
              s4 << r7
            end
          end
          if s4.last
            r4 = instantiate_node(SyntaxNode,input, i4...index, s4)
            r4.extend(ArrayBrackets0)
          else
            self.index = i4
            r4 = nil
          end
          if r4
            s3 << r4
          else
            break
          end
        end
        r3 = instantiate_node(SyntaxNode,input, i3...index, s3)
        s0 << r3
      end
    end
    if s0.last
      r0 = instantiate_node(ArrayBracketsNode,input, i0...index, s0)
      r0.extend(ArrayBrackets1)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:array_brackets][start_index] = r0

    return r0
  end

  module Const0
    def space
      elements[1]
    end
  end

  def _nt_const
    start_index = index
    if node_cache[:const].has_key?(index)
      cached = node_cache[:const][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    if input.index('const', index) == index
      r1 = instantiate_node(SyntaxNode,input, index...(index + 5))
      @index += 5
    else
      terminal_parse_failure('const')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(Const0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:const][start_index] = r0

    return r0
  end

  module Asterisk0
    def space
      elements[1]
    end
  end

  def _nt_asterisk
    start_index = index
    if node_cache[:asterisk].has_key?(index)
      cached = node_cache[:asterisk][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    if input.index('*', index) == index
      r1 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure('*')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(Asterisk0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:asterisk][start_index] = r0

    return r0
  end

  module LeftParen0
    def space
      elements[1]
    end
  end

  def _nt_left_paren
    start_index = index
    if node_cache[:left_paren].has_key?(index)
      cached = node_cache[:left_paren][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    if input.index('(', index) == index
      r1 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure('(')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(LeftParen0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:left_paren][start_index] = r0

    return r0
  end

  module RightParen0
    def space
      elements[1]
    end
  end

  def _nt_right_paren
    start_index = index
    if node_cache[:right_paren].has_key?(index)
      cached = node_cache[:right_paren][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    if input.index(')', index) == index
      r1 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure(')')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(RightParen0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:right_paren][start_index] = r0

    return r0
  end

  module LeftBracket0
    def space
      elements[1]
    end
  end

  def _nt_left_bracket
    start_index = index
    if node_cache[:left_bracket].has_key?(index)
      cached = node_cache[:left_bracket][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    if input.index('[', index) == index
      r1 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure('[')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(LeftBracket0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:left_bracket][start_index] = r0

    return r0
  end

  module RightBracket0
    def space
      elements[1]
    end
  end

  def _nt_right_bracket
    start_index = index
    if node_cache[:right_bracket].has_key?(index)
      cached = node_cache[:right_bracket][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    if input.index(']', index) == index
      r1 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure(']')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(RightBracket0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:right_bracket][start_index] = r0

    return r0
  end

  module Comma0
    def space
      elements[1]
    end
  end

  def _nt_comma
    start_index = index
    if node_cache[:comma].has_key?(index)
      cached = node_cache[:comma][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    if input.index(',', index) == index
      r1 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      terminal_parse_failure(',')
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(Comma0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:comma][start_index] = r0

    return r0
  end

  module Number0
    def space
      elements[1]
    end
  end

  def _nt_number
    start_index = index
    if node_cache[:number].has_key?(index)
      cached = node_cache[:number][index]
      @index = cached.interval.end if cached
      return cached
    end

    i0, s0 = index, []
    if input.index(Regexp.new('[0-9]'), index) == index
      r1 = instantiate_node(SyntaxNode,input, index...(index + 1))
      @index += 1
    else
      r1 = nil
    end
    s0 << r1
    if r1
      r2 = _nt_space
      s0 << r2
    end
    if s0.last
      r0 = instantiate_node(SyntaxNode,input, i0...index, s0)
      r0.extend(Number0)
    else
      self.index = i0
      r0 = nil
    end

    node_cache[:number][start_index] = r0

    return r0
  end

  def _nt_space
    start_index = index
    if node_cache[:space].has_key?(index)
      cached = node_cache[:space][index]
      @index = cached.interval.end if cached
      return cached
    end

    s0, i0 = [], index
    loop do
      if input.index(' ', index) == index
        r1 = instantiate_node(SyntaxNode,input, index...(index + 1))
        @index += 1
      else
        terminal_parse_failure(' ')
        r1 = nil
      end
      if r1
        s0 << r1
      else
        break
      end
    end
    r0 = instantiate_node(SyntaxNode,input, i0...index, s0)

    node_cache[:space][start_index] = r0

    return r0
  end

end

class CMockFunctionPrototypeParser < Treetop::Runtime::CompiledParser
  include CMockFunctionPrototype
end

