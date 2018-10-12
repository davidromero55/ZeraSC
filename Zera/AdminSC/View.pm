package Zera::AdminSC::View;

use JSON;
use base 'Zera::BaseAdmin::View';

sub display_brands {
    my $self = shift;

    $self->set_title('Brands');
    $self->add_search_box();
    $self->set_add_btn('/AdminSC/BrandsEdit/New', 'Add');

    # Helper buttons
    $self->add_btn('/AdminSC','Back');

    my $where;
    my @params;
    if($self->param('zl_q')){
        $where .= " name LIKE ? ";
        push(@params,'%' . $self->param('zl_q') .'%');
    }
    my $list = Zera::List->new($self->{Zera},{
        sql => {
            select => "brand_id, name, active",
            from =>"sc_brands e",
            order_by => "2",
            where => $where,
            params => \@params,
            limit => "30",
        },
        link => {
            key => "brand_id",
            hidde_key_col => 1,
            location => '/AdminSC/BrandsEdit',
            transit_params => {},
        },
        debug => 1,
    });

    $list->get_data();
    $list->on_off('active');
    $list->columns_align(['left','center']);

    return $list->render();
}

sub display_brands_edit {
    my $self = shift;
    my $values = {};
    my @submit = ("Save");

    $self->param('brand_id',$self->param('SubView')) if(!($self->param('brand_id')));

    # Title
    ($self->param('SubView') eq 'New') ? $self->set_title('Add Brand') : $self->set_title('Edit Brand');

    # Helper buttons
    $self->add_btn('/AdminSC/Brands','Back');

    # Values
    if($self->param('brand_id') ne 'New'){
        $values = $self->selectrow_hashref("SELECT *, image as photo  FROM sc_brands WHERE brand_id=?",{},$self->param('brand_id'));
        push(@submit, 'Delete');

    }else{
        $values = {
            active => 1,
            photo  => '',
        };
    }

    # Form
    my $form = $self->form({
        method   => 'POST',
        fields   => [qw/brand_id name description image active /],
        submits  => \@submit,
        values   => $values,
    });

    $form->field('brand_id',{type=>'hidden'});
    $form->field('name',{span=>'col-md-9', required=>1});
    $form->field('description',{span=>'col-md-9', required=>1});
    $form->field('image', {type=>'file', accept=>"image/x-png,image/gif,image/jpeg", span=>'col-6'});
    $form->field('active',{label=>"Active", span=>'col-md-1', check_label=>'Yes / No', class=>"filled-in", type=>"checkbox"});

    $form->submit('Delete',{class=>'btn btn-danger'});
    if($values->{photo}){
        $form->field('photo',{label=>"Logo", span=>'col-md-12', type=>"image"});
        push(@submit, 'Delete Logo');
        $form->submit('Delete Logo',{class=>'btn btn-danger'});
        #$form->field('image', {help=>$self->get_image_options($values->{display_options}->{image})});
    }

    return $form->render();
}

sub display_options {
    my $self = shift;

    $self->set_title('Options');
    $self->add_search_box();
    $self->set_add_btn('/AdminSC/OptionsEdit/New', 'Add');

    my $where;
    my @params;
    if($self->param('zl_q')){
        $where .= " o.option LIKE ? ";
        push(@params,'%' . $self->param('zl_q') .'%');
    }
    my $list = Zera::List->new($self->{Zera},{
        sql => {
            select => "o.option_id, o.option, '' AS edit",
            from =>"sc_options o",
            order_by => "",
            where => $where,
            params => \@params,
            limit => "50",
        },
        link => {
            key => "option_id",
            hidde_key_col => 1,
            transit_params => {},
        },
        debug => 1,
    });

    $list->get_data();
    $list->on_off('active');
    $list->columns_align(['left','center']);

    foreach my $row (@{$list->{rs}}){
        $row->{edit} .= $self->_tag('a',{class=>'mr-3 btn btn-outline-primary btn-sm', href=>'/AdminSC/OptionsEdit/'.$row->{option_id}},'<i class="fas fa-edit"></i>');
        $row->{edit} .= $self->_tag('a',{class=>'mr-3 btn btn-outline-primary btn-sm', href=>'/AdminSC/OptionDetails/'.$row->{option_id}},'<i class="fas fa-chevron-right"></i>');
    }

    return $list->render();
}

sub display_options_edit {
    my $self = shift;
    my $values = {};
    my @submit = ("Save");

    $self->param('option_id',$self->param('SubView')) if(!($self->param('option_id')));

    # Title
    ($self->param('SubView') eq 'New') ? $self->set_title('Add Option') : $self->set_title('Edit Option');

    # Helper buttons
    $self->add_btn('/AdminSC/Options','Back');

    # Values
    if($self->param('option_id') ne 'New'){
        $values = $self->selectrow_hashref("SELECT * FROM sc_options WHERE option_id=?",{},$self->param('option_id'));
        push(@submit, 'Delete');
    }else{
        $values = {
            active => 1,
        };
    }

    # Form
    my $form = $self->form({
        method   => 'POST',
        fields   => [qw/option_id option/],
        submits  => \@submit,
        values   => $values,
    });

    $form->field('option_id',{type=>'hidden'});
    $form->field('option',{span=>'col-md-3', required=>1});
    $form->submit('Delete',{class=>'btn btn-danger'});

    return $form->render();
}

sub display_option_details {
    my $self = shift;

    $self->param('option_id',$self->param('SubView')) if(!($self->param('option_id')));
    $self->param('value_id',$self->param('UrlId')) if(!($self->param('value_id')));
    $self->add_btn('/AdminSC/Options','Back');

    my $option = $self->selectrow_hashref("SELECT * FROM sc_options WHERE option_id=?",{},$self->param('option_id'));
    $self->set_title('Product Option values for: ' . $option->{option});
    my $vars = {
        option_form  => $self->get_option_form(),
        options_list => $self->get_options_list(),
    };
    return $self->render_template($vars);
}

sub get_option_form {
    my $self = shift;
    my $values = {};
    my @submit = ("Save");
    if($self->param('value_id')){
        $values = $self->selectrow_hashref(
            "SELECT value_id, option_id, option_value FROM sc_options_values WHERE value_id=? AND option_id=?",{},
            $self->param('value_id'), $self->param('option_id'));
            @submit = ("Save","Delete");
    }
    # Form
    my $form = $self->form({
        method   => 'POST',
        fields   => [qw/option_id value_id option_value/],
        submits  => \@submit,
        values   => $values,
        template => 'get_option_form',
    });

    $form->field('option_id',{type=>'hidden'});
    $form->field('value_id',{type=>'hidden'});
    $form->field('option_value',{span=>'col-md-3', required=>1, placeholder=>'Option value'});

    $form->submit('Delete',{class=>'btn btn-sm mr-1 btn-danger'});
    $form->submit('Save',{class=>'btn btn-sm mr-1 btn-primary'});

    return $form->render();
}

sub get_options_list {
    my $self = shift;

    my $list = Zera::List->new($self->{Zera},{
        pagination => 0,
        sql => {
            select => "value_id, option_value,'' AS edit",
            from =>"sc_options_values",
            order_by => "option_value",
            where => "option_id=?",
            params => [$self->param('option_id')],
        },
        link => {
            key => "value_id",
            hidde_key_col => 1,
            location => '/AdminSC/OptionDetails/'.$self->param('option_id'),
            transit_params => {},
        },
    });

    $list->get_data();
    $list->on_off('active');
    $list->columns_align(['left','center']);

    foreach my $row (@{$list->{rs}}){
        $row->{edit} = '<i class="fas fa-edit"></i>';
    }
    my $vars = {
        list => $list->print(),
    };

    return $self->render_template($vars,'options_list');

}

sub display_categories {
    my $self = shift;

    $self->param('category_id',$self->param('SubView')) if(!($self->param('category_id')));
    $self->set_add_btn('/AdminSC/CategoryEdit/New', 'Add');
    $self->add_btn('/AdminSC','Back');
    $self->set_title('Product Categories');

    my $categories = $self->selectall_arrayref("SELECT category_id, name, sort_order FROM sc_categories WHERE parent_id=0 ORDER BY sort_order",{Slice=>{}});

    foreach my $category (@$categories){
        $category->{childs} = $self->selectall_arrayref("SELECT category_id, name, sort_order FROM sc_categories WHERE parent_id=? ORDER BY sort_order",
            {Slice=>{}},$category->{category_id});
    }

    my $vars = {
        categories => $categories,
    };
    return $self->render_template($vars);
}

sub display_category_edit {
    my $self = shift;
    my $values = {};
    my @submit = ("Save");

    $self->param('category_id',$self->param('SubView')) if(!($self->param('category_id')));
    $self->param('parent_id','0') if(!($self->param('parent_id')));

    # Title
    $self->set_title('Category');

    # Helper buttons
    $self->add_btn('/AdminSC/Categories','Back');

    # JS
    $self->add_jsfile('admin-sc');

    # Values
    if($self->param('category_id') ne 'New'){
        $values = $self->selectrow_hashref("SELECT *  FROM sc_categories WHERE category_id=?",{},$self->param('category_id'));
        push(@submit, 'Delete');
    }else{
        $values = {
            active => 1,
            sort_order => 1,
        };
    }

    # Form
    my $form = $self->form({
        method   => 'POST',
        fields   => [qw/category_id parent_id name url description sort_order active image details/],
        submits  => \@submit,
        values   => $values,
    });

    $form->field('category_id',{type=>'hidden'});
    $form->field('parent_id',{type=>'hidden'});
    $form->field('name',{span=>'col-md-9', required=>1});
    $form->field('url',{span=>'col-md-6', required=>1, readonly=>1});
    $form->field('description',{span=>'col-md-9', required=>1});
    $form->field('active',{label=>"Active", span=>'col-md-1', check_label=>'Yes / No', class=>"filled-in", type=>"checkbox"});
    $form->field('image', {type=>'file', accept=>"image/x-png,image/gif,image/jpeg", span=>'col-12'});
    $form->field('details',{span=>'col-md-12', class=>'wysiwyg'});

    if($values->{image}){
        $form->field('image',{span=>'col-md-12', help=>$self->_tag('img',{src=>'/data/category_thumb/'.$values->{image}}) });
        push(@submit, 'Delete Image');
        $form->submit('Delete Image',{class=>'btn btn-danger'});
    }

    return $form->render();
}

sub display_category_child {
    my $self = shift;
    my $values = {};
    my @submit = ("Save");

    $self->param('parent_id',$self->param('SubView')) if(!($self->param('parent_id')));
    $self->param('category_id','0') if(!($self->param('category_id')));
    my $parent = $self->selectrow_hashref("SELECT category_id, name FROM sc_categories WHERE category_id=?",{},
        $self->param('parent_id'));

    # Title
    $self->set_title('Category Child for: ' . $parent->{name});

    # Helper buttons
    $self->add_btn('/AdminSC/Categories','Back');

    # JS
    $self->add_jsfile('admin-sc');

    # Values
    if($self->param('category_id')){
        $values = $self->selectrow_hashref("SELECT * FROM sc_categories WHERE category_id=?",{},$self->param('category_id'));
        push(@submit, 'Delete');
    }else{
        $values = {
            parent_id => $self->param('parent_id'),
            sort_order => 1,
            active => 1,
        };
    }

    # Form
    my $form = $self->form({
        method   => 'POST',
        fields   => [qw/category_id parent_id name url description sort_order active image details/],
        submits  => \@submit,
        values   => $values,
    });

    $form->field('category_id',{type=>'hidden'});
    $form->field('parent_id',{type=>'hidden'});
    $form->field('name',{span=>'col-md-9', required=>1});
    $form->field('url',{span=>'col-md-6', required=>1, readonly=>1});
    $form->field('description',{span=>'col-md-9', required=>1});
    $form->field('active',{label=>"Active", span=>'col-md-1', check_label=>'Yes / No', class=>"filled-in", type=>"checkbox"});
    $form->field('image', {type=>'file', accept=>"image/x-png,image/gif,image/jpeg", span=>'col-12'});
    $form->field('details',{span=>'col-md-12', class=>'wysiwyg'});

    if($values->{image}){
        $form->field('image',{span=>'col-md-12', help=>$self->_tag('img',{src=>'/data/category_thumb/'.$values->{image}}) });
        push(@submit, 'Delete Image');
        $form->submit('Delete Image',{class=>'btn btn-danger'});
    }

    return $form->render();
}

sub display_products {
    my $self = shift;

    $self->set_title('Products');
    $self->add_search_box();
    $self->set_add_btn('/AdminSC/ProductsEdit', 'Add');

    # Helper buttons
    $self->add_btn('/AdminSC','Back');

    my $where;
    my @params;
    if($self->param('zl_q')){
        $where .= " name LIKE ? ";
        push(@params,'%' . $self->param('zl_q') .'%');
    }
    my $list = Zera::List->new($self->{Zera},{
        sql => {
            select => "product_id, code, name, active",
            from =>"sc_products p",
            order_by => "p.active DESC, 3",
            where => $where,
            params => \@params,
            limit => "30",
        },
        link => {
            key => "product_id",
            hidde_key_col => 1,
            location => '/AdminSC/ProductsEdit',
            transit_params => {},
        },
    });

    $list->get_data();
    $list->on_off('active');
    $list->columns_align(['left','left','center']);

    return $list->render();
}

sub display_products_edit {
    my $self = shift;
    my $values = {};
    my @submit = ("Save");

    $self->param('product_id',$self->param('SubView')) if(!($self->param('product_id')));

    # Title
    ($self->param('product_id')) ? $self->set_title('Edit Product') : $self->set_title('Add Product');

    # Helper buttons
    $self->add_btn('/AdminSC/Products','Back');

    if($self->param('product_id')) {
        $values = $self->selectrow_hashref(
            "SELECT p.code, p.name, p.keywords, p.image, p.option_id, p.brand_id, p.active FROM sc_products p WHERE p.product_id=?",{},
            $self->param('product_id'));
        push(@submit, 'Delete');
    }else{
        $values = {
            active => 1,
        };
    }

    # Form
    my $form = $self->form({
        method   => 'POST',
        fields   => [qw/code name keywords image option_id brand_id active/],
        submits  => \@submit,
        values   => $values,
#        template => 'display_product',
    });
    my %options = $self->selectbox_data("SELECT option_id, option FROM sc_options");
    my %brands = $self->selectbox_data("SELECT brand_id, name FROM sc_brands order by name");
    $form->field('product_id',{type=>'hidden'});
    $form->field('code',{span=>'col-md-4', required=>1});
    $form->field('name',{span=>'col-md-8', required=>1});
    $form->field('keywords',{span=>'col-6'});
    $form->field('image', {type=>'file', accept=>"image/x-png,image/gif,image/jpeg", span=>'col-6'});
    $form->field('option_id',{placeholder=> 'Option', span=>'col-md-4', label=> 'Options', type=>'select', selectname => 'Select a option', options => $options{values}, labels => $options{labels}, required=>1});
    $form->field('brand_id' ,{placeholder=> 'Brand', span=>'col-md-4', label=> 'Brands', type=>'select', selectname => 'Select a brand', options => $brands{values}, labels => $brands{labels}, required=>1});
    $form->field('active',{label=>"Publish", span=>'col-md-4', check_label=>'Yes / No', class=>"filled-in", type=>"checkbox"});

    if($values->{display_options}->{image}){
        $form->field('image', {help=>$self->get_image_options($values->{display_options}->{image})});
    }

    $form->submit('Delete',{class=>'btn btn-danger'});

    return $form->render();
}

1;
