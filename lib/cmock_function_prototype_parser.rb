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

    def left_paren
      elements[1]
    end

    def asterisk
      elements[2]
    end

    def const
      elements[3]
    end

    def name
      elements[4]
    end

    def right_paren
      elements[5]
    end

    def argument_list
      elements[6]
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
      r2 = _nt_left_paren
      s0 << r2
      if r2
        r3 = _nt_asterisk
        s0 << r3
        if r3
          r5 = _nt_const
          if r5
            r4 = r5
          else
            r4 = instantiate_node(SyntaxNode,input, index...index)
          end
          s0 << r4
          if r4
            r7 = _nt_name
            if r7
              r6 = r7
            else
              r6 = instantiate_node(SyntaxNode,input, index...index)
            end
            s0 << r6
            if r6
              r8 = _nt_right_paren
              s0 << r8
              if r8
                r9 = _nt_argument_list
                s0 << r9
              end
            end
          end
        end
      end
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
      r3 = _nt_name
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
          r6 = _nt_type_void_ptr
          if r6
            r3 = r6
          else
            r7 = _nt_type_primitive
            if r7
              r3 = r7
            else
              r8 = _nt_type_custom
              if r8
                r3 = r8
              else
                self.index = i3
                r3 = nil
              end
            end
          end
        end
      end
      s0 << r3
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
    def const
      elements[0]
    end

    def space
      elements[1]
    end

  end

  module TypeConstAndPtrSuffix1
    def const
      elements[0]
    end

    def space
      elements[1]
    end
  end

  module TypeConstAndPtrSuffix2
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
    r2 = _nt_const
    s1 << r2
    if r2
      r3 = _nt_space
      s1 << r3
      if r3
        s4, i4 = [], index
        loop do
          r5 = _nt_asterisk
          if r5
            s4 << r5
          else
            break
          end
        end
        if s4.empty?
          self.index = i4
          r4 = nil
        else
          r4 = instantiate_node(SyntaxNode,input, i4...index, s4)
        end
        s1 << r4
      end
    end
    if s1.last
      r1 = instantiate_node(SyntaxNode,input, i1...index, s1)
      r1.extend(TypeConstAndPtrSuffix0)
    else
      self.index = i1
      r1 = nil
    end
    if r1
      r0 = r1
    else
      i6, s6 = index, []
      s7, i7 = [], index
      loop do
        r8 = _nt_asterisk
        if r8
          s7 << r8
        else
          break
        end
      end
      if s7.empty?
        self.index = i7
        r7 = nil
      else
        r7 = instantiate_node(SyntaxNode,input, i7...index, s7)
      end
      s6 << r7
      if r7
        i10, s10 = index, []
        r11 = _nt_const
        s10 << r11
        if r11
          r12 = _nt_space
          s10 << r12
        end
        if s10.last
          r10 = instantiate_node(SyntaxNode,input, i10...index, s10)
          r10.extend(TypeConstAndPtrSuffix1)
        else
          self.index = i10
          r10 = nil
        end
        if r10
          r9 = r10
        else
          r9 = instantiate_node(SyntaxNode,input, index...index)
        end
        s6 << r9
      end
      if s6.last
        r6 = instantiate_node(SyntaxNode,input, i6...index, s6)
        r6.extend(TypeConstAndPtrSuffix2)
      else
        self.index = i6
        r6 = nil
      end
      if r6
        r0 = r6
      else
        self.index = i0
        r0 = nil
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

